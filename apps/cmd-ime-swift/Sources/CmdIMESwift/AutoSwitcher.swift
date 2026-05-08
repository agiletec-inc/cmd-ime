import Cocoa
import Carbon.HIToolbox

@MainActor
final class AutoSwitcher {
    static let shared = AutoSwitcher()
    private init() {}

    // Remembered input source ID per bundle identifier.
    private var perAppSource: [String: String] = [:]
    private var currentAppID: String = ""

    // When in a URL field, this holds the source to restore on exit.
    private var savedBeforeURLField: String?

    private var pollTimer: Timer?

    // Call once on app launch; timer runs forever but is a no-op when disabled.
    func start() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            // Timer callbacks aren't @MainActor, but AutoSwitcher is always on main
            // thread and this timer is scheduled on the main RunLoop.
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    // Called by KeyEvent.setActiveApp on every app switch.
    func handleAppActivation(bundleID: String, pid: pid_t) {
        guard AppSettings.shared.autoSwitching else { return }
        guard bundleID != currentAppID else { return }

        // Save current source for the outgoing app.
        if !currentAppID.isEmpty {
            perAppSource[currentAppID] = currentInputSourceID()
        }

        // Restore remembered source for the incoming app.
        if let saved = perAppSource[bundleID] {
            selectInputSource(id: saved)
        }

        currentAppID = bundleID
        savedBeforeURLField = nil
    }

    // MARK: - URL field polling

    private func tick() {
        guard AppSettings.shared.autoSwitching else {
            // Feature disabled: clear any outstanding URL field state.
            if savedBeforeURLField != nil { restoreFromURLField() }
            return
        }
        checkURLField()
    }

    private func checkURLField() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              exclusionAppsDict[bundleID] == nil else {
            restoreFromURLField()
            return
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedRef: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef
        ) == .success, let focused = focusedRef else {
            restoreFromURLField()
            return
        }

        // swiftlint:disable:next force_cast
        if isURLTextField(focused as! AXUIElement) {
            if savedBeforeURLField == nil {
                savedBeforeURLField = currentInputSourceID()
                selectASCIICapable()
            }
        } else {
            restoreFromURLField()
        }
    }

    private func restoreFromURLField() {
        guard let saved = savedBeforeURLField else { return }
        selectInputSource(id: saved)
        savedBeforeURLField = nil
    }

    // MARK: - URL field detection

    private func isURLTextField(_ element: AXUIElement) -> Bool {
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              (roleRef as? String) == kAXTextFieldRole else { return false }

        // Check description and identifier for browser URL bar hints.
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
