//
//  AppSettings.swift
//  ⌘IME
//
//  Single source of truth for user-facing preferences. Wraps UserDefaults
//  and SMAppService and keeps the legacy globals consumed by KeyEvent
//  (`keyMappingList`, `shortcutList`, `exclusionAppsList`, `exclusionAppsDict`)
//  in sync with the published state.
//

import Cocoa
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum Keys {
        static let launchAtStartup = "launchAtStartup"
        static let legacyLaunchAtStartup = "lunchAtStartup"
        static let showMenuBarIcon = "showIcon"
        static let checkUpdateAtLaunch = "checkUpdateAtLaunch"
        static let legacyCheckUpdateAtLaunch = "checkUpdateAtlaunch"
        static let keyMappings = "mappings"
        static let exclusionApps = "exclusionApps"
    }

    private let defaults: UserDefaults

    @Published var launchAtStartup: Bool
    @Published var showMenuBarIcon: Bool
    @Published var checkUpdateAtLaunch: Bool
    @Published var keyMappings: [KeyMapping]
    @Published var exclusionApps: [AppData]

    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingExternalUpdate = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        Self.migrateLegacyKeys(in: defaults)

        self.showMenuBarIcon = (defaults.object(forKey: Keys.showMenuBarIcon) as? Int ?? 1) != 0
        self.checkUpdateAtLaunch = (defaults.object(forKey: Keys.checkUpdateAtLaunch) as? Int ?? 1) != 0

        let stored = (defaults.object(forKey: Keys.launchAtStartup) as? Int ?? 0) != 0
        let serviceEnabled = SMAppService.mainApp.status == .enabled
        self.launchAtStartup = stored || serviceEnabled

        self.keyMappings = Self.loadKeyMappings(from: defaults)
        self.exclusionApps = Self.loadExclusionApps(from: defaults)

        publishGlobalsFromState()
        observePropertyChanges()
    }

    /// Call once on app launch to reconcile any drift between SMAppService
    /// (the OS-side login item registry) and our stored toggle.
    func bootstrap() {
        let serviceEnabled = SMAppService.mainApp.status == .enabled
        if launchAtStartup && !serviceEnabled {
            // Stored intent is "on" (incl. migrated legacy value) but the OS
            // never registered us — register now so the next login honors it.
            setLaunchAtStartup(true)
        } else if !launchAtStartup && serviceEnabled {
            // OS already registered us (e.g. enabled in System Settings) but
            // the stored toggle is off. Follow the OS state.
            launchAtStartup = true
        }
    }

    // MARK: - Mutators surfaced to SwiftUI

    func addKeyMapping() {
        keyMappings.append(KeyMapping())
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
                setLaunchAtStartup(newValue)
            }
            .store(in: &cancellables)

        $showMenuBarIcon
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.defaults.set(newValue ? 1 : 0, forKey: Keys.showMenuBarIcon)
                statusItem.isVisible = newValue
            }
            .store(in: &cancellables)

        $checkUpdateAtLaunch
            .dropFirst()
            .sink { [weak self] newValue in
                self?.defaults.set(newValue ? 1 : 0, forKey: Keys.checkUpdateAtLaunch)
            }
            .store(in: &cancellables)

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
                exclusionAppsList = apps
                exclusionAppsDict = Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0.name) })
            }
            .store(in: &cancellables)
    }

    private func publishGlobalsFromState() {
        keyMappingList = keyMappings
        keyMappingListToShortcutList()
        exclusionAppsList = exclusionApps
        exclusionAppsDict = Dictionary(uniqueKeysWithValues: exclusionApps.map { ($0.id, $0.name) })
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
    }

    private static func loadKeyMappings(from defaults: UserDefaults) -> [KeyMapping] {
        if let raw = defaults.object(forKey: Keys.keyMappings) as? [[AnyHashable: Any]] {
            let parsed = raw.compactMap { KeyMapping(dictionary: $0) }
            if !parsed.isEmpty { return parsed }
        }
        return Self.defaultKeyMappings
    }

    private static func loadExclusionApps(from defaults: UserDefaults) -> [AppData] {
        guard let raw = defaults.object(forKey: Keys.exclusionApps) as? [[AnyHashable: Any]] else {
            return []
        }
        return raw.compactMap { AppData(dictionary: $0) }
    }

    static let defaultKeyMappings: [KeyMapping] = [
        KeyMapping(input: KeyboardShortcut(keyCode: 55), output: KeyboardShortcut(keyCode: 102)),
        KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
    ]
}
