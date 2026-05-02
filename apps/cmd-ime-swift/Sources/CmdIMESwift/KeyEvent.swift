//
//  KeyEvent.swift
//  ⌘IME
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

var activeAppsList: [AppData] = []
var exclusionAppsList: [AppData] = []

var exclusionAppsDict: [String: String] = [:]

class KeyEvent: NSObject {
    var keyCode: CGKeyCode?
    var isExclusionApp = false
    let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "com.kazuki.cmdime"
    var hasConvertedEventLog: KeyMapping?

    override init() {
        super.init()
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

        NSEvent.addGlobalMonitorForEvents(matching: nsEventMaskList) {(_: NSEvent) in
            self.keyCode = nil
        }

        NSEvent.addLocalMonitorForEvents(matching: nsEventMaskList) {(event: NSEvent) -> NSEvent? in
            self.keyCode = nil
            return event
        }

        // CGEvent tap can run on main thread's RunLoop since NSApplication.run() handles it
        setupCGEventTap()
    }

    private var eventTap: CFMachPort?
    private var tapRetryAttempts = 0

    func setupCGEventTap() {
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

        let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())

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
            Unmanaged<KeyEvent>.fromOpaque(observer).release()
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

        eventTap = tap
        tapRetryAttempts = 0

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Re-enable if the tap is disabled (timeout or input-source failure).
        // Without this the user has to relaunch when macOS pauses the tap.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(reenableTapIfNeeded),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func reenableTapIfNeeded() {
        guard let tap = eventTap else { return }
        if !CGEvent.tapIsEnabled(tap: tap) {
            NSLog("⌘IME: CGEvent tap was disabled by the system; re-enabling.")
            CGEvent.tapEnable(tap: tap, enable: true)
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
        if isExclusionApp || isRecordingShortcut {
            return Unmanaged.passRetained(event)
        }

        if let mediaKeyEvent = MediaKeyEvent(event) {
            return mediaKeyEvent.keyDown ? mediaKeyDown(mediaKeyEvent) : mediaKeyUp(mediaKeyEvent)
        }

        switch type {
        case CGEventType.flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            if modifierMasks[keyCode] == nil {
                return Unmanaged.passRetained(event)
            }
            return event.flags.rawValue & modifierMasks[keyCode]!.rawValue != 0 ?
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
            // print("keyCode: \(KeyboardShortcut(event).keyCode)")
             print(KeyboardShortcut(event).toString())
        #endif

        self.keyCode = nil

        if hasConvertedEvent(event) {
            if let event = getConvertedEvent(event) {
                return Unmanaged.passRetained(event)
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    func keyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        self.keyCode = nil

        if hasConvertedEvent(event) {
            if let event = getConvertedEvent(event) {
                return Unmanaged.passRetained(event)
            }
            return nil
        }

        return Unmanaged.passRetained(event)
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
            if let convertedEvent = getConvertedEvent(event) {
                KeyboardShortcut(convertedEvent).postEvent()
            }
        }

        self.keyCode = nil

        return Unmanaged.passRetained(event)
    }

    func mediaKeyDown(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            let shortcut = KeyboardShortcut(
                keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode),
                flags: mediaKeyEvent.flags
            )
            print(shortcut.toString())
        #endif

        self.keyCode = nil

        let mediaKeyCodeValue = CGKeyCode(1000 + mediaKeyEvent.keyCode)
        if hasConvertedEvent(mediaKeyEvent.event, keyCode: mediaKeyCodeValue) {
            if let event = getConvertedEvent(mediaKeyEvent.event, keyCode: mediaKeyCodeValue) {
                print(KeyboardShortcut(event).toString())

                print(event.type == CGEventType.keyDown)
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
            return nil
        }

        return Unmanaged.passRetained(mediaKeyEvent.event)
    }

    func mediaKeyUp(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        return Unmanaged.passRetained(mediaKeyEvent.event)
    }

    func hasConvertedEvent(_ event: CGEvent, keyCode: CGKeyCode? = nil) -> Bool {
        let shortcht = event.type.rawValue == UInt32(NX_SYSDEFINED) ?
            KeyboardShortcut(keyCode: 0, flags: MediaKeyEvent(event)!.flags) : KeyboardShortcut(event)

        if let mappingList = shortcutList[keyCode ?? shortcht.keyCode] {
            for mappings in mappingList where shortcht.isCover(mappings.input) {
                hasConvertedEventLog = mappings
                return true
            }
        }
        hasConvertedEventLog = nil
        return false
    }
    func getConvertedEvent(_ event: CGEvent, keyCode: CGKeyCode? = nil) -> CGEvent? {
        var event = event

        if event.type.rawValue == UInt32(NX_SYSDEFINED) {
            let flags = MediaKeyEvent(event)!.flags
            event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
            event.flags = flags
        }

        let shortcht = KeyboardShortcut(event)

        func getEvent(_ mappings: KeyMapping) -> CGEvent? {
            if mappings.output.keyCode == 999 {
                // 999 is Disable
                return nil
            }

            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappings.output.keyCode))
            event.flags = CGEventFlags(
                rawValue: (event.flags.rawValue & ~mappings.input.flags.rawValue) | mappings.output.flags.rawValue
            )

            return event
        }

        if let mappingList = shortcutList[keyCode ?? shortcht.keyCode] {
            if let mappings = hasConvertedEventLog,
                shortcht.isCover(mappings.input) {

                return getEvent(mappings)
            }
            for mappings in mappingList where shortcht.isCover(mappings.input) {
                return getEvent(mappings)
            }
        }
        return nil
    }
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
