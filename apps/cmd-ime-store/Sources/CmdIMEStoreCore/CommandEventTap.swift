import CoreGraphics
import Foundation

public final class CommandEventTap {
    public enum StartResult: Equatable {
        case started
        case permissionRequired
        case eventTapUnavailable
    }

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var policy = CommandTapPolicy()
    private let onTap: (CommandSide) -> Void
    private let accessCheck: () -> Bool
    private let accessRequest: () -> Bool

    public init(
        accessCheck: @escaping () -> Bool = CGPreflightListenEventAccess,
        accessRequest: @escaping () -> Bool = CGRequestListenEventAccess,
        onTap: @escaping (CommandSide) -> Void
    ) {
        self.accessCheck = accessCheck
        self.accessRequest = accessRequest
        self.onTap = onTap
    }

    deinit { stop() }

    public var hasListenEventAccess: Bool { accessCheck() }

    /// Permission is requested only after an explicit user action.
    @discardableResult
    public func requestAccessAndStart() -> StartResult {
        guard accessCheck() || accessRequest() else { return .permissionRequired }
        return start()
    }

    @discardableResult
    public func start() -> StartResult {
        guard accessCheck() else { return .permissionRequired }
        stop()

        let mask = CGEventMask(1) << CGEventType.flagsChanged.rawValue
        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let owner = Unmanaged<CommandEventTap>.fromOpaque(userInfo).takeUnretainedValue()
                owner.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            return .eventTapUnavailable
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            return .eventTapUnavailable
        }

        tap = eventTap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return .started
    }

    public func stop() {
        policy.reset()
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CFMachPortInvalidate(tap)
        self.tap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            policy.reset()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard type == .flagsChanged else { return }
        let rawKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard let side = CommandSide.allCases.first(where: { Int64($0.keyCode) == rawKeyCode }) else {
            // Any intervening modifier transition cancels an in-progress bare tap.
            policy.reset()
            return
        }

        let isPressed = CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(side.keyCode))
        let otherSide: CommandSide = side == .left ? .right : .left
        let anotherCommandHeld = CGEventSource.keyState(
            .combinedSessionState,
            key: CGKeyCode(otherSide.keyCode)
        )
        let flags = event.flags
        var modifiers: ModifierSnapshot = []
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        let keyDownCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)

        if let accepted = policy.flagsChanged(
            side: side,
            isPressed: isPressed,
            modifiers: modifiers,
            keyDownCount: keyDownCount,
            anotherCommandHeld: anotherCommandHeld
        ) {
            onTap(accepted)
        }
    }

}
