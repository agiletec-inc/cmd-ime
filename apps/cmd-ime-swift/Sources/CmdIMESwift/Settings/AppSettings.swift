//
//  AppSettings.swift
//  ⌘IME
//
//  Single source of truth for user-facing preferences. Wraps UserDefaults
//  and SMAppService and keeps the legacy globals consumed by KeyEvent
//  (`keyMappingList`, `shortcutList`, `exclusionAppsDict`)
//  in sync with the published state.
//

import Cocoa
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum SwitchingMode: Int {
        case global = 0   // no automatic switching
        case perApp = 1   // remember input source per app
        case smart = 2    // perApp + context-aware field detection
    }

    enum Keys {
        static let launchAtStartup = "launchAtStartup"
        static let legacyLaunchAtStartup = "lunchAtStartup"
        static let showMenuBarIcon = "showIcon"
        static let checkUpdateAtLaunch = "checkUpdateAtLaunch"
        static let legacyCheckUpdateAtLaunch = "checkUpdateAtlaunch"
        static let quitOnCommandQ = "quitOnCommandQ"
        static let keyMappings = "mappings"
        static let exclusionApps = "exclusionApps"
        static let switchingMode = "switchingMode"
        static let legacyAutoSwitching = "autoSwitching"
    }

    private let defaults: UserDefaults

    @Published var launchAtStartup: Bool
    @Published var showMenuBarIcon: Bool
    @Published var checkUpdateAtLaunch: Bool
    @Published var quitOnCommandQ: Bool
    @Published var keyMappings: [KeyMapping]
    @Published var exclusionApps: [AppData]
    @Published var switchingMode: SwitchingMode

    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingExternalUpdate = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        Self.migrateLegacyKeys(in: defaults)

        self.showMenuBarIcon = (defaults.object(forKey: Keys.showMenuBarIcon) as? Int ?? 1) != 0
        self.checkUpdateAtLaunch = (defaults.object(forKey: Keys.checkUpdateAtLaunch) as? Int ?? 1) != 0
        // Default off: ⌘Q keeps the agent in the menu bar and only closes the window.
        self.quitOnCommandQ = (defaults.object(forKey: Keys.quitOnCommandQ) as? Int ?? 0) != 0

        let stored = (defaults.object(forKey: Keys.launchAtStartup) as? Int ?? 0) != 0
        let serviceEnabled = SMAppService.mainApp.status == .enabled
        self.launchAtStartup = stored || serviceEnabled

        self.keyMappings = Self.loadKeyMappings(from: defaults)
        self.exclusionApps = Self.loadExclusionApps(from: defaults)
        self.switchingMode = Self.loadSwitchingMode(from: defaults)

        publishGlobalsFromState()
        observePropertyChanges()
    }

    /// Call once on app launch to reconcile any drift between SMAppService
    /// (the OS-side login item registry) and our stored toggle.
    func bootstrap() {
        let serviceEnabled = SMAppService.mainApp.status == .enabled
        if launchAtStartup && !serviceEnabled {
            // Stored intent is "on" but the OS is not enabled. Which way to
            // resolve this depends on *why* the service isn't enabled, so
            // switch on the actual status instead of treating every
            // non-enabled state the same:
            switch SMAppService.mainApp.status {
            case .requiresApproval:
                // The item IS registered with SMAppService, but the user
                // disabled it (or hasn't approved it yet) in System
                // Settings → Login Items. Follow the OS state instead of
                // force re-registering behind the user's back. Use the
                // re-entrancy guard (same pattern as the sink's revert path
                // below) so the Combine sink doesn't also try to mutate the
                // OS-side registration while we just sync our stored toggle
                // to match reality.
                isApplyingExternalUpdate = true
                launchAtStartup = false
                defaults.set(0, forKey: Keys.launchAtStartup)
                isApplyingExternalUpdate = false
            default:
                // .notRegistered / .notFound (plus any unknown future
                // status, handled here too): we were never registered with
                // SMAppService at all, so there's no "user turned it off in
                // System Settings" to defer to. Most likely this is a user
                // upgrading from a pre-SMAppService version whose legacy
                // `lunchAtStartup=true` was carried over by
                // migrateLegacyKeys(in:) but who never went through
                // SMAppService registration. Honor the stored intent and
                // register now — this restores the pre-fix behavior for
                // this specific case only.
                setLaunchAtStartup(true)
            }
        } else if !launchAtStartup && serviceEnabled {
            // OS already registered us (e.g. enabled in System Settings) but
            // the stored toggle is off. Follow the OS state.
            launchAtStartup = true
        }
    }

    // MARK: - Mutators surfaced to SwiftUI

    func addKeyMapping() {
        // Start disabled: KeyMapping()'s default shortcut is keyCode 0 (the
        // "A" key), so a bare enabled row would immediately remap A → A
        // until the user picks a real input/output through the preset
        // menus. updateKeyMapping(at:) re-enables it once both are set.
        keyMappings.append(KeyMapping(input: KeyboardShortcut(), output: KeyboardShortcut(), enable: false))
    }

    func removeKeyMapping(at index: Int) {
        guard keyMappings.indices.contains(index) else { return }
        keyMappings.remove(at: index)
    }

    func moveKeyMapping(from source: IndexSet, to destination: Int) {
        keyMappings.move(fromOffsets: source, toOffset: destination)
    }

    func updateKeyMapping(at index: Int, input: KeyboardShortcut? = nil, output: KeyboardShortcut? = nil) {
        guard keyMappings.indices.contains(index) else { return }
        if let input = input { keyMappings[index].input = input }
        if let output = output { keyMappings[index].output = output }
        // A freshly-added row stays disabled until both sides have been
        // explicitly chosen through the preset menus (see addKeyMapping()).
        if !keyMappings[index].input.isUnset && !keyMappings[index].output.isUnset {
            keyMappings[index].enable = true
        }
        keyMappings = keyMappings  // trigger didSet
    }

    func addExclusion(_ app: AppData) {
        guard !exclusionApps.contains(where: { $0.id == app.id }) else { return }
        exclusionApps.append(app)
    }

    func removeExclusion(at index: Int) {
        guard exclusionApps.indices.contains(index) else { return }
        exclusionApps.remove(at: index)
    }

    // MARK: - Internals

    private func observePropertyChanges() {
        $launchAtStartup
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self, !self.isApplyingExternalUpdate else { return }
                self.defaults.set(newValue ? 1 : 0, forKey: Keys.launchAtStartup)
                if !setLaunchAtStartup(newValue) {
                    self.isApplyingExternalUpdate = true
                    self.launchAtStartup = !newValue
                    self.defaults.set(!newValue ? 1 : 0, forKey: Keys.launchAtStartup)
                    self.isApplyingExternalUpdate = false
                }
            }
            .store(in: &cancellables)

        $showMenuBarIcon
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.defaults.set(newValue ? 1 : 0, forKey: Keys.showMenuBarIcon)
                AppDelegate.shared?.statusItem.isVisible = newValue
            }
            .store(in: &cancellables)

        persistToggle($checkUpdateAtLaunch, to: Keys.checkUpdateAtLaunch)
        persistToggle($quitOnCommandQ, to: Keys.quitOnCommandQ)

        $keyMappings
            .dropFirst()
            .sink { [weak self] mappings in
                guard let self = self else { return }
                self.defaults.set(mappings.map { $0.toDictionary() }, forKey: Keys.keyMappings)
                keyMappingList = mappings
                keyMappingListToShortcutList()
            }
            .store(in: &cancellables)

        $exclusionApps
            .dropFirst()
            .sink { [weak self] apps in
                guard let self = self else { return }
                self.defaults.set(apps.map { $0.toDictionary() }, forKey: Keys.exclusionApps)
                exclusionAppsDict = Dictionary(apps.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
            }
            .store(in: &cancellables)

        $switchingMode
            .dropFirst()
            .sink { [weak self] newValue in
                self?.defaults.set(newValue.rawValue, forKey: Keys.switchingMode)
            }
            .store(in: &cancellables)
    }

    /// Persists a published Bool toggle to UserDefaults (stored as 0/1) on change.
    private func persistToggle(_ publisher: Published<Bool>.Publisher, to key: String) {
        publisher
            .dropFirst()
            .sink { [weak self] newValue in
                self?.defaults.set(newValue ? 1 : 0, forKey: key)
            }
            .store(in: &cancellables)
    }

    private func publishGlobalsFromState() {
        keyMappingList = keyMappings
        keyMappingListToShortcutList()
        exclusionAppsDict = Dictionary(exclusionApps.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    private static func migrateLegacyKeys(in defaults: UserDefaults) {
        if defaults.object(forKey: Keys.launchAtStartup) == nil,
           let legacy = defaults.object(forKey: Keys.legacyLaunchAtStartup) {
            defaults.set(legacy, forKey: Keys.launchAtStartup)
            defaults.removeObject(forKey: Keys.legacyLaunchAtStartup)
        }
        if defaults.object(forKey: Keys.checkUpdateAtLaunch) == nil,
           let legacy = defaults.object(forKey: Keys.legacyCheckUpdateAtLaunch) {
            defaults.set(legacy, forKey: Keys.checkUpdateAtLaunch)
            defaults.removeObject(forKey: Keys.legacyCheckUpdateAtLaunch)
        }
        // autoSwitching (Bool) → switchingMode (Int): true maps to .smart
        if defaults.object(forKey: Keys.switchingMode) == nil {
            let old = (defaults.object(forKey: Keys.legacyAutoSwitching) as? Int ?? 0) != 0
            defaults.set(old ? SwitchingMode.smart.rawValue : SwitchingMode.global.rawValue,
                         forKey: Keys.switchingMode)
            defaults.removeObject(forKey: Keys.legacyAutoSwitching)
        }
    }

    private static func loadSwitchingMode(from defaults: UserDefaults) -> SwitchingMode {
        let raw = defaults.object(forKey: Keys.switchingMode) as? Int ?? SwitchingMode.global.rawValue
        return SwitchingMode(rawValue: raw) ?? .global
    }

    private static func loadKeyMappings(from defaults: UserDefaults) -> [KeyMapping] {
        // A stored array is authoritative — including an empty one (the user
        // deliberately removed every mapping). Only fall back to the factory
        // defaults when the key was never written or isn't an array.
        guard let raw = defaults.object(forKey: Keys.keyMappings) as? [[AnyHashable: Any]] else {
            return Self.defaultKeyMappings
        }
        return raw.compactMap { KeyMapping(dictionary: $0) }
    }

    private static func loadExclusionApps(from defaults: UserDefaults) -> [AppData] {
        guard let raw = defaults.object(forKey: Keys.exclusionApps) as? [[AnyHashable: Any]] else {
            return []
        }
        let parsed = raw.compactMap { AppData(dictionary: $0) }
        // De-dup by id (keep first occurrence) so a duplicate entry in
        // persisted data (e.g. hand-edited defaults, a prior bug) can never
        // reach the rest of the app as two entries with the same id.
        var seenIDs = Set<String>()
        return parsed.filter { seenIDs.insert($0.id).inserted }
    }

    static let defaultKeyMappings: [KeyMapping] = [
        KeyMapping(input: KeyboardShortcut(keyCode: 55), output: KeyboardShortcut(keyCode: 102)),
        KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
    ]
}
