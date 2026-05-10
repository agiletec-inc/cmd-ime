//
//  AutoSwitcher.swift
//  ⌘IME
//

import Cocoa
import Carbon.HIToolbox

@MainActor
final class AutoSwitcher {
    static let shared = AutoSwitcher()
    private init() {}

    // Remembered input source ID per bundle identifier.
    private var perAppSource: [String: String] = [:]
    private var currentAppID: String = ""

    // When in an auto-switch field, this holds the source to restore on exit.
    private var savedBeforeAutoField: String?

    private var pollTimer: Timer?

    // Call once on app launch; timer runs forever but is a no-op when disabled.
    func start() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    // Called by KeyEvent.setActiveApp on every app switch.
    func handleAppActivation(bundleID: String, pid: pid_t) {
        let mode = AppSettings.shared.switchingMode
        guard mode == .perApp || mode == .smart else { return }
        guard bundleID != currentAppID else { return }

        if !currentAppID.isEmpty {
            perAppSource[currentAppID] = currentInputSourceID()
        }

        if let saved = perAppSource[bundleID] {
            selectInputSource(id: saved)
        }

        currentAppID = bundleID
        savedBeforeAutoField = nil
    }

    // MARK: - Field polling (smart mode only)

    private func tick() {
        guard AppSettings.shared.switchingMode == .smart else {
            if savedBeforeAutoField != nil { restoreFromAutoField() }
            return
        }
        checkSmartField()
    }

    private func checkSmartField() {
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

    // MARK: - ASCII-only field detection

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
            kTISPropertyInputSourceIsEnabled as String: true,
        ] as CFDictionary
        guard let cfList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else { return }
        let list = cfList as NSArray
        guard let first = list.firstObject else { return }
        // swiftlint:disable:next force_cast
        TISSelectInputSource((first as! TISInputSource))
    }
}
