//
//  AutoSwitcher.swift
//  ⌘IME
//

import Cocoa
import Carbon.HIToolbox
import Combine

@MainActor
final class AutoSwitcher {
    static let shared = AutoSwitcher()
    private init() {}

    // Remembered input source ID per bundle identifier.
    private var perAppSource: [String: String] = [:]
    private var currentAppID: String = ""

    // When in an auto-switch field, this holds the source to restore on exit.
    private var savedBeforeAutoField: String?

    // AXObserver watching focus changes in the frontmost app (smart mode only).
    // Replaces the old 500ms polling timer: the field is re-evaluated only when
    // the focused UI element actually changes, not on a fixed schedule.
    private var focusObserver: AXObserver?
    private var observedPID: pid_t?
    private var modeCancellable: AnyCancellable?

    // Call once on app launch.
    func start() {
        // React to switching-mode changes: attach the focus observer when smart
        // mode is turned on, tear it down (and restore the input source) when it
        // is turned off. @Published delivers the current value on subscription,
        // so this also performs the initial wiring.
        modeCancellable = AppSettings.shared.$switchingMode
            .sink { [weak self] mode in
                MainActor.assumeIsolated { self?.applySwitchingMode(mode) }
            }
    }

    // Called by KeyEvent.setActiveApp on every app switch.
    func handleAppActivation(bundleID: String, pid: pid_t) {
        let mode = AppSettings.shared.switchingMode
        guard mode == .perApp || mode == .smart else { return }

        // Re-point the focus observer at the newly activated app. Done before the
        // same-app guard so an app relaunch (new pid, same bundle id) re-attaches.
        if mode == .smart {
            attachFocusObserver(pid: pid)
        }

        guard bundleID != currentAppID else { return }

        if !currentAppID.isEmpty {
            perAppSource[currentAppID] = currentInputSourceID()
        }

        if let saved = perAppSource[bundleID] {
            selectInputSource(id: saved)
        }

        currentAppID = bundleID
        savedBeforeAutoField = nil

        if mode == .smart {
            checkSmartField()
        }
    }

    private func applySwitchingMode(_ mode: AppSettings.SwitchingMode) {
        if mode == .smart {
            attachFocusObserverToFrontmostApp()
            checkSmartField()
        } else {
            detachFocusObserver()
            restoreFromAutoField()
        }
    }

    // MARK: - Focus observer (smart mode only)

    private func attachFocusObserverToFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        attachFocusObserver(pid: app.processIdentifier)
    }

    private func attachFocusObserver(pid: pid_t) {
        // Already watching this process — nothing to do.
        guard observedPID != pid else { return }
        detachFocusObserver()

        var observer: AXObserver?
        // The C callback cannot capture context; it is handed `self` via refcon.
        let created = AXObserverCreate(pid, { _, _, _, refcon in
            guard let refcon else { return }
            let switcher = Unmanaged<AutoSwitcher>.fromOpaque(refcon).takeUnretainedValue()
            MainActor.assumeIsolated { switcher.checkSmartField() }
        }, &observer)

        guard created == .success, let observer else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        for notification in [
            kAXFocusedUIElementChangedNotification,
            kAXFocusedWindowChangedNotification
        ] as [String] {
            AXObserverAddNotification(observer, appElement, notification as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

        focusObserver = observer
        observedPID = pid
    }

    private func detachFocusObserver() {
        guard let observer = focusObserver else { return }
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        focusObserver = nil
        observedPID = nil
    }

    // MARK: - ASCII-only field detection

    private func checkSmartField() {
        guard AppSettings.shared.switchingMode == .smart else {
            restoreFromAutoField()
            return
        }

        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              exclusionAppsDict[bundleID] == nil else {
            restoreFromAutoField()
            return
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedRef: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef
        ) == .success, let focused = focusedRef else {
            restoreFromAutoField()
            return
        }

        // swiftlint:disable:next force_cast
        if isASCIIOnlyField(focused as! AXUIElement) {
            if savedBeforeAutoField == nil {
                savedBeforeAutoField = currentInputSourceID()
                selectASCIICapable()
            }
        } else {
            restoreFromAutoField()
        }
    }

    private func restoreFromAutoField() {
        guard let saved = savedBeforeAutoField else { return }
        selectInputSource(id: saved)
        savedBeforeAutoField = nil
    }

    private func isASCIIOnlyField(_ element: AXUIElement) -> Bool {
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String else { return false }

        // URL bars in browsers
        if role == (kAXTextFieldRole as String) && isURLTextField(element) { return true }

        // Only inspect text fields and combo boxes further
        guard role == (kAXTextFieldRole as String) || role == (kAXComboBoxRole as String) else { return false }

        let asciiHints = ["url", "address", "location", "phone", "tel", "email",
                          "zip", "postal", "number", "numeric", "code", "pin", "otp"]
        for attr in [kAXDescriptionAttribute, kAXIdentifierAttribute,
                     kAXPlaceholderValueAttribute, kAXTitleUIElementAttribute] as [String] {
            var ref: AnyObject?
            guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success,
                  let str = ref as? String else { continue }
            let lower = str.lowercased()
            if asciiHints.contains(where: { lower.contains($0) }) { return true }
        }
        return false
    }

    private func isURLTextField(_ element: AXUIElement) -> Bool {
        for attr in [kAXDescriptionAttribute, kAXIdentifierAttribute] as [String] {
            var ref: AnyObject?
            guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success,
                  let str = ref as? String else { continue }
            let lower = str.lowercased()
            if lower.contains("address") || lower.contains("url") || lower.contains("location") {
                return true
            }
        }
        return false
    }

    // MARK: - Input source helpers

    private func currentInputSourceID() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return "" }
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private func selectInputSource(id: String) {
        guard !id.isEmpty else { return }
        let conditions = [kTISPropertyInputSourceID as String: id] as CFDictionary
        guard let cfList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else { return }
        let list = cfList as NSArray
        guard let first = list.firstObject else { return }
        // swiftlint:disable:next force_cast
        TISSelectInputSource((first as! TISInputSource))
    }

    private func selectASCIICapable() {
        let conditions = [
            kTISPropertyInputSourceIsASCIICapable as String: true,
            kTISPropertyInputSourceIsEnabled as String: true
        ] as CFDictionary
        guard let cfList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else { return }
        let list = cfList as NSArray
        guard let first = list.firstObject else { return }
        // swiftlint:disable:next force_cast
        TISSelectInputSource((first as! TISInputSource))
    }
}
