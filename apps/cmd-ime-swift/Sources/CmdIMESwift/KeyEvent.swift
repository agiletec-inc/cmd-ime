//
//  KeyEvent.swift
//  ⌘IME
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

var activeAppsList: [AppData] = []

var exclusionAppsDict: [String: String] = [:]

private enum EventConversion {
    case passThrough
    case disable
    case remap(CGEvent)
}

class KeyEvent: NSObject {
    var keyCode: CGKeyCode?
    var isExclusionApp = false
    let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "com.kazuki.cmdime"

    private var eventTap: CFMachPort?
    private var tapRetryAttempts = 0
    private var tapObserver: Unmanaged<KeyEvent>?
    private var tapHeartbeat: Timer?
    private var nsEventMonitors: [Any] = []

    override init() {
        super.init()
    }

    deinit {
        tapHeartbeat?.invalidate()
        tapObserver?.release()
        nsEventMonitors.forEach { NSEvent.removeMonitor($0) }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        CGDisplayRemoveReconfigurationCallback(
            displayReconfigurationCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
    }

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                            selector: #selector(KeyEvent.setActiveApp(_:)),
                                                            name: NSWorkspace.didActivateApplicationNotification,
                                                            object: nil)

        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        let options: CFDictionary = [checkOptionPrompt: true] as NSDictionary

        if !AXIsProcessTrustedWithOptions(options) {
            // Wait until the user grants Accessibility permission.
            Timer.scheduledTimer(timeInterval: 1.0,
                                 target: self,
                                 selector: #selector(KeyEvent.watchAXIsProcess(_:)),
                                 userInfo: nil,
                                 repeats: true)
        } else {
            // Setup event monitoring (must be called from main thread for NSEvent monitors)
            setupEventMonitoring()
        }
    }

    @objc func watchAXIsProcess(_ timer: Timer) {
        if AXIsProcessTrusted() {
            timer.invalidate()
            // Setup event monitoring (must be called from main thread for NSEvent monitors)
            setupEventMonitoring()
        }
    }

    @objc func setActiveApp(_ notification: NSNotification) {
        guard let app = notification.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication else {
            return
        }

        if let name = app.localizedName, let id = app.bundleIdentifier {
            isExclusionApp = exclusionAppsDict[id] != nil

            if id != bundleId && !isExclusionApp {
                activeAppsList = activeAppsList.filter {$0.id != id}
                activeAppsList.insert(AppData(name: name, id: id), at: 0)

                if activeAppsList.count > 10 {
                    activeAppsList.removeLast()
                }
            }

            // NSWorkspace notifications always fire on the main thread.
            MainActor.assumeIsolated {
                AutoSwitcher.shared.handleAppActivation(bundleID: id, pid: app.processIdentifier)
            }
        }
    }

    func setupEventMonitoring() {
        // Pair NSEvent + CGEvent monitors to work around a mouse-drag bug
        // where keyCode tracking would otherwise stick.
        // NSEvent monitors must be set up on main thread.
        let nsEventMaskList: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .scrollWheel
        ]

        if let m = NSEvent.addGlobalMonitorForEvents(matching: nsEventMaskList, handler: { [weak self] _ in
            self?.keyCode = nil
        }) { nsEventMonitors.append(m) }

        if let m = NSEvent.addLocalMonitorForEvents(matching: nsEventMaskList, handler: { [weak self] event in
            self?.keyCode = nil
            return event
        }) { nsEventMonitors.append(m) }

        // CGEvent tap can run on main thread's RunLoop since NSApplication.run() handles it
        setupCGEventTap()

        // Watch for display add/remove/mode changes. A monitor connect/disconnect
        // can leave the session tap half-dead (tapIsEnabled() still reports true,
        // so the heartbeat never recreates it). Force a rebuild on reconfiguration.
        CGDisplayRegisterReconfigurationCallback(
            displayReconfigurationCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
    }

    func handleDisplayReconfiguration(flags: CGDisplayChangeSummaryFlags) {
        // Reconfiguration fires twice (begin + end); act only on the end pass.
        if flags.contains(.beginConfigurationFlag) { return }
        guard shouldRebuildTap(for: flags) else { return }

        NSLog("⌘IME: display reconfiguration detected; rebuilding CGEvent tap.")
        setupCGEventTap()
    }

    func shouldRebuildTap(for flags: CGDisplayChangeSummaryFlags) -> Bool {
        let relevant: CGDisplayChangeSummaryFlags = [
            .addFlag, .removeFlag, .enabledFlag, .disabledFlag, .setModeFlag
        ]
        return !flags.isDisjoint(with: relevant)
    }

    func setupCGEventTap() {
        // Release resources from any previous tap attempt.
        tapHeartbeat?.invalidate()
        tapHeartbeat = nil
        tapObserver?.release()
        tapObserver = nil

        let eventMaskList = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
            UInt32(NX_SYSDEFINED) // Media key Event
        ]
        var eventMask: UInt32 = 0

        for mask in eventMaskList {
            eventMask |= (1 << mask)
        }

        let retained = Unmanaged.passRetained(self)
        let observer = UnsafeMutableRawPointer(retained.toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let observer = refcon {
                    let mySelf = Unmanaged<KeyEvent>.fromOpaque(observer).takeUnretainedValue()
                    return mySelf.eventCallback(proxy: proxy, type: type, event: event)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: observer
        ) else {
            // CGEvent.tapCreate can return nil even after AXIsProcessTrusted
            // returns true if tccd hasn't fully propagated the grant yet
            // (suspected cause of the post-install hang in #5). Retry on a
            // short timer for up to ~30 seconds before giving up loudly —
            // never `exit(1)` here, that just hides the problem.
            retained.release()
            tapRetryAttempts += 1
            NSLog("⌘IME: CGEvent.tapCreate returned nil (attempt %d). Retrying…", tapRetryAttempts)
            if tapRetryAttempts >= 30 {
                NSLog("⌘IME: giving up on CGEvent tap after %d attempts. Restart the app or revoke + re-grant Accessibility.", tapRetryAttempts)
                presentTapFailureAlert()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.setupCGEventTap()
            }
            return
        }

        tapObserver = retained
        eventTap = tap
        tapRetryAttempts = 0

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Proactively re-enable the tap every 5 seconds in case the system
        // disables it (e.g., on input-source change or system load).
        tapHeartbeat = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.reenableTapIfNeeded()
        }
    }

    @objc private func reenableTapIfNeeded() {
        guard let tap = eventTap else { return }
        guard !CGEvent.tapIsEnabled(tap: tap) else { return }

        NSLog("⌘IME: CGEvent tap was disabled by the system; re-enabling.")
        CGEvent.tapEnable(tap: tap, enable: true)

        if !CGEvent.tapIsEnabled(tap: tap) {
            NSLog("⌘IME: Re-enable failed — recreating tap.")
            setupCGEventTap()
        }
    }

    private func presentTapFailureAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "⌘IME could not start its keyboard listener"
            alert.informativeText =
                "Open System Settings → Privacy & Security → Accessibility, " +
                "remove ⌘IME if listed, re-add it, then restart the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
            NSApplication.shared.terminate(nil)
        }
    }

    func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system delivers the tap-disabled types to this callback when it
        // disables the tap (timeout under load, or display reconfiguration on
        // monitor connect/disconnect — #107). Re-enable immediately instead of
        // waiting for the 5-second heartbeat.
        if type.isTapDisabled {
            NSLog("⌘IME: CGEvent tap disabled by system (type %u); re-enabling.", type.rawValue)
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        if isExclusionApp || isRecordingShortcut {
            return Unmanaged.passRetained(event)
        }

        if let mediaKeyEvent = MediaKeyEvent(event) {
            return mediaKeyEvent.keyDown ? mediaKeyDown(mediaKeyEvent) : mediaKeyUp(mediaKeyEvent)
        }

        switch type {
        case CGEventType.flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            guard let mask = modifierMasks[keyCode] else {
                return Unmanaged.passRetained(event)
            }
            return event.flags.rawValue & mask.rawValue != 0 ?
                modifierKeyDown(event) : modifierKeyUp(event)

        case CGEventType.keyDown:
            return keyDown(event)

        case CGEventType.keyUp:
            return keyUp(event)

        default:
            self.keyCode = nil

            return Unmanaged.passRetained(event)
        }
    }

    func keyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            print(KeyboardShortcut(event).toString())
        #endif

        self.keyCode = nil

        switch convertedEvent(for: event) {
        case .passThrough:       return Unmanaged.passRetained(event)
        case .disable:           return nil
        case .remap(let mapped): return Unmanaged.passRetained(mapped)
        }
    }

    func keyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        self.keyCode = nil

        switch convertedEvent(for: event) {
        case .passThrough:       return Unmanaged.passRetained(event)
        case .disable:           return nil
        case .remap(let mapped): return Unmanaged.passRetained(mapped)
        }
    }

    func modifierKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            print(KeyboardShortcut(event).toString())
        #endif

        self.keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        return Unmanaged.passRetained(event)
    }

    func modifierKeyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        if self.keyCode == CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)) {
            if case .remap(let converted) = convertedEvent(for: event) {
                KeyboardShortcut(converted).postEvent()
            }
        }

        self.keyCode = nil

        return Unmanaged.passRetained(event)
    }

    func mediaKeyDown(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        self.keyCode = nil

        let mediaKeyCodeValue = CGKeyCode(1000 + mediaKeyEvent.keyCode)
        switch convertedEvent(for: mediaKeyEvent.event, keyCode: mediaKeyCodeValue) {
        case .passThrough:
            return Unmanaged.passRetained(mediaKeyEvent.event)
        case .disable:
            return nil
        case .remap(let mapped):
            #if DEBUG
            print(KeyboardShortcut(mapped).toString())
            print(mapped.type == CGEventType.keyDown)
            #endif
            mapped.post(tap: .cgSessionEventTap)
            return nil
        }
    }

    func mediaKeyUp(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        return Unmanaged.passRetained(mediaKeyEvent.event)
    }

    // MARK: - Key mapping

    private func findMapping(for event: CGEvent, keyCode: CGKeyCode? = nil) -> KeyMapping? {
        let shortcut: KeyboardShortcut
        if event.type.rawValue == UInt32(NX_SYSDEFINED) {
            guard let mediaKey = MediaKeyEvent(event) else { return nil }
            shortcut = KeyboardShortcut(keyCode: 0, flags: mediaKey.flags)
        } else {
            shortcut = KeyboardShortcut(event)
        }

        let lookupKey = keyCode ?? shortcut.keyCode
        guard let mappingList = shortcutList[lookupKey] else { return nil }

        for mapping in mappingList where mapping.enable && shortcut.isCover(mapping.input) {
            return mapping
        }
        return nil
    }

    private func convertedEvent(for event: CGEvent, keyCode: CGKeyCode? = nil) -> EventConversion {
        guard let mapping = findMapping(for: event, keyCode: keyCode) else { return .passThrough }

        if mapping.output.keyCode == 999 { return .disable }

        // Build the remapped event on a fresh CGEvent so the caller's event is
        // never mutated as a side effect — modifierKeyUp forwards the original.
        let ev: CGEvent
        if event.type.rawValue == UInt32(NX_SYSDEFINED) {
            guard let mediaFlags = MediaKeyEvent(event)?.flags,
                  let synthesized = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
                return .passThrough
            }
            synthesized.flags = mediaFlags
            ev = synthesized
        } else {
            guard let copy = event.copy() else { return .passThrough }
            ev = copy
        }

        ev.setIntegerValueField(.keyboardEventKeycode, value: Int64(mapping.output.keyCode))
        ev.flags = CGEventFlags(
            rawValue: (ev.flags.rawValue & ~mapping.input.flags.rawValue) | mapping.output.flags.rawValue
        )
        return .remap(ev)
    }
}

extension CGEventType {
    /// Types the system delivers to a tap callback when it disables the tap.
    var isTapDisabled: Bool {
        self == .tapDisabledByTimeout || self == .tapDisabledByUserInput
    }
}

/// File-level function so it converts to a stable C function pointer, letting
/// `CGDisplayRemoveReconfigurationCallback` match the registration in `deinit`.
private func displayReconfigurationCallback(
    _ display: CGDirectDisplayID,
    _ flags: CGDisplayChangeSummaryFlags,
    _ userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo else { return }
    let keyEvent = Unmanaged<KeyEvent>.fromOpaque(userInfo).takeUnretainedValue()
    keyEvent.handleDisplayReconfiguration(flags: flags)
}

let modifierMasks: [CGKeyCode: CGEventFlags] = [
    54: CGEventFlags.maskCommand,
    55: CGEventFlags.maskCommand,
    56: CGEventFlags.maskShift,
    60: CGEventFlags.maskShift,
    59: CGEventFlags.maskControl,
    62: CGEventFlags.maskControl,
    58: CGEventFlags.maskAlternate,
    61: CGEventFlags.maskAlternate,
    63: CGEventFlags.maskSecondaryFn,
    57: CGEventFlags.maskAlphaShift
]
