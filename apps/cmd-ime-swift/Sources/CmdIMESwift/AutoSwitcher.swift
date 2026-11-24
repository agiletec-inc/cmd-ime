//
//  AutoSwitcher.swift
//  ⌘IME
//

import Cocoa
import Carbon.HIToolbox
import Combine

struct SmartFocusRequests {
    struct Target: Equatable, Sendable {
        let pid: pid_t
        let bundleID: String
    }

    struct Request: Equatable, Sendable {
        let target: Target
        fileprivate let generation: UInt64
    }

    private(set) var target: Target?
    private var generation: UInt64 = 0
    private var pending: Request?
    private var inFlight = false

    mutating func update(target: Target?) {
        generation &+= 1
        self.target = target
        pending = target.map { Request(target: $0, generation: generation) }
    }

    mutating func begin() -> Request? {
        guard !inFlight, let request = pending else { return nil }
        pending = nil
        inFlight = true
        return request
    }

    // Observer registration and its first read share one in-flight slot.
    mutating func beginRead(after request: Request) -> Request? {
        guard target == request.target else { return nil }
        defer { pending = nil }
        return pending ?? request
    }

    mutating func finish() {
        inFlight = false
    }

    func isCurrent(_ request: Request) -> Bool {
        request.generation == generation && target == request.target
    }
}

@MainActor
final class AutoSwitcher {
    static let shared = AutoSwitcher()
    private init() {}

    // Remembered input source ID per bundle identifier.
    private var perAppSource: [String: String] = [:]
    private var currentAppID: String = ""

    // When in an auto-switch field, this holds the source to restore on exit.
    private var savedBeforeAutoField: String?

    // Observer callbacks and input-source changes live on main. Both AX
    // registration and attribute reads may wait on another process.
    private let accessibilityQueue = DispatchQueue(label: "CmdIME.smart-accessibility", qos: .userInitiated)
    private var focusObserver: AXObserver?
    private var requests = SmartFocusRequests()
    private var modeCancellable: AnyCancellable?

    // Call once on app launch.
    func start() {
        modeCancellable = AppSettings.shared.$switchingMode
            .sink { [weak self] mode in
                MainActor.assumeIsolated { self?.applySwitchingMode(mode) }
            }
    }

    // Called by KeyEvent.setActiveApp on every app switch.
    func handleAppActivation(bundleID: String, pid: pid_t) {
        let mode = AppSettings.shared.switchingMode
        guard mode == .perApp || mode == .smart else { return }

        if bundleID != currentAppID {
            if !currentAppID.isEmpty {
                perAppSource[currentAppID] = currentInputSourceID()
            }

            if let saved = perAppSource[bundleID] {
                selectInputSource(id: saved)
            }

            currentAppID = bundleID
            savedBeforeAutoField = nil
        }

        if mode == .smart {
            updateFocusTarget(SmartFocusRequests.Target(pid: pid, bundleID: bundleID))
        }
    }

    private func applySwitchingMode(_ mode: AppSettings.SwitchingMode) {
        updateFocusTarget(mode == .smart ? frontmostFocusTarget() : nil)
    }

    private func frontmostFocusTarget() -> SmartFocusRequests.Target? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return nil }
        return SmartFocusRequests.Target(pid: app.processIdentifier, bundleID: bundleID)
    }

    // MARK: - Focus observer (smart mode only)

    private func updateFocusTarget(_ target: SmartFocusRequests.Target?) {
        let target = target.flatMap { exclusionAppsDict[$0.bundleID] == nil ? $0 : nil }
        if requests.target != target {
            detachFocusObserver()
        }
        requests.update(target: target)
        if target == nil {
            restoreFromAutoField()
        }
        startPendingRequest()
    }

    private func startPendingRequest() {
        guard let request = requests.begin() else { return }

        guard focusObserver == nil else {
            readFocus(request)
            return
        }

        accessibilityQueue.async { [self] in
            let observer = Self.makeFocusObserver(pid: request.target.pid, switcher: self)
            DispatchQueue.main.async { [self] in
                guard AppSettings.shared.switchingMode == .smart,
                      frontmostFocusTarget() == request.target,
                      exclusionAppsDict[request.target.bundleID] == nil,
                      let next = requests.beginRead(after: request) else {
                    requests.finish()
                    startPendingRequest()
                    return
                }

                // Install the source before reading attributes so intervening
                // notifications can invalidate the result.
                if let observer {
                    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
                    focusObserver = observer
                }
                readFocus(next)
            }
        }
    }

    private func readFocus(_ request: SmartFocusRequests.Request) {
        accessibilityQueue.async { [self] in
            let isASCIIOnly = Self.isFocusedFieldASCIIOnly(pid: request.target.pid)
            DispatchQueue.main.async { [self] in
                requests.finish()
                if requests.isCurrent(request),
                   AppSettings.shared.switchingMode == .smart,
                   frontmostFocusTarget() == request.target {
                    if exclusionAppsDict[request.target.bundleID] != nil {
                        updateFocusTarget(nil)
                    } else if let isASCIIOnly {
                        applyFocusedField(isASCIIOnly: isASCIIOnly)
                    }
                }
                startPendingRequest()
            }
        }
    }

    private func applyFocusedField(isASCIIOnly: Bool) {
        if !isASCIIOnly {
            restoreFromAutoField()
        } else if savedBeforeAutoField == nil {
            savedBeforeAutoField = currentInputSourceID()
            selectASCIICapable()
        }
    }

    private nonisolated static func makeFocusObserver(pid: pid_t, switcher: AutoSwitcher) -> AXObserver? {
        dispatchPrecondition(condition: .notOnQueue(.main))
        var observer: AXObserver?
        let created = AXObserverCreate(pid, { observer, _, _, refcon in
            guard let refcon else { return }
            let switcher = Unmanaged<AutoSwitcher>.fromOpaque(refcon).takeUnretainedValue()
            MainActor.assumeIsolated {
                guard switcher.focusObserver === observer,
                      AppSettings.shared.switchingMode == .smart else { return }
                switcher.updateFocusTarget(switcher.frontmostFocusTarget())
            }
        }, &observer)

        guard created == .success, let observer else { return nil }

        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.075)
        let refcon = Unmanaged.passUnretained(switcher).toOpaque()
        var registered = false
        for notification in [
            kAXFocusedUIElementChangedNotification,
            kAXFocusedWindowChangedNotification
        ] as [String] {
            if AXObserverAddNotification(observer, appElement, notification as CFString, refcon) == .success {
                registered = true
            }
        }
        return registered ? observer : nil
    }

    private func detachFocusObserver() {
        guard let focusObserver else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(focusObserver), .defaultMode)
        self.focusObserver = nil
    }

    // MARK: - ASCII-only field detection

    private func restoreFromAutoField() {
        guard let saved = savedBeforeAutoField else { return }
        selectInputSource(id: saved)
        savedBeforeAutoField = nil
    }

    // nil means the current field could not be classified reliably.
    private nonisolated static func isFocusedFieldASCIIOnly(pid: pid_t) -> Bool? {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.075)
        var focusedRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef
        )
        guard focusResult == .success else {
            return isAbsentAttribute(focusResult) ? false : nil
        }
        guard let focusedRef, CFGetTypeID(focusedRef) == AXUIElementGetTypeID() else { return nil }

        // AXUIElement is the CF type checked above.
        // swiftlint:disable:next force_cast
        let element = focusedRef as! AXUIElement
        AXUIElementSetMessagingTimeout(element, 0.075)
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard roleResult == .success, let role = roleRef as? String else { return nil }
        guard role == kAXTextFieldRole || role == kAXComboBoxRole else { return false }

        // Inspect only field metadata. Never read the field's value or selection.
        let attributes = [
            kAXDescriptionAttribute, kAXIdentifierAttribute, kAXPlaceholderValueAttribute, kAXTitleAttribute
        ]
        var values: CFArray?
        guard AXUIElementCopyMultipleAttributeValues(element, attributes as CFArray, [], &values) == .success,
              let metadata = values as? [AnyObject] else { return nil }
        return classifyFieldMetadata(metadata)
    }

    private nonisolated static func isAbsentAttribute(_ error: AXError) -> Bool {
        error == .attributeUnsupported || error == .noValue || error == .notImplemented
    }

    nonisolated static func classifyFieldMetadata(_ metadata: [AnyObject]) -> Bool? {
        let asciiHints = ["url", "address", "location", "phone", "tel", "email",
                          "zip", "postal", "number", "numeric", "code", "pin", "otp"]
        var hasUnknownAttribute = false
        for value in metadata {
            if let text = value as? String {
                let lower = text.lowercased()
                if asciiHints.contains(where: { lower.contains($0) }) { return true }
            } else if CFGetTypeID(value) == AXValueGetTypeID() {
                // swiftlint:disable:next force_cast
                let errorValue = value as! AXValue
                var error = AXError.success
                if AXValueGetValue(errorValue, .axError, &error), !isAbsentAttribute(error) {
                    hasUnknownAttribute = true
                }
            }
        }
        return hasUnknownAttribute ? nil : false
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
