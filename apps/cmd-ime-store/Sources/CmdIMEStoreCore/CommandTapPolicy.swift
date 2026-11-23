import Foundation

public enum CommandSide: String, CaseIterable, Sendable {
    case left
    case right

    public var keyCode: UInt16 {
        switch self {
        case .left: 55
        case .right: 54
        }
    }
}

public struct ModifierSnapshot: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let command = Self(rawValue: 1 << 0)
    public static let shift = Self(rawValue: 1 << 1)
    public static let option = Self(rawValue: 1 << 2)
    public static let control = Self(rawValue: 1 << 3)
    public static let function = Self(rawValue: 1 << 4)

    fileprivate var hasNonCommandModifier: Bool {
        !intersection([.shift, .option, .control, .function]).isEmpty
    }
}

/// Pure policy for accepting a bare left/right Command tap.
/// It stores only counts and modifier state, never ordinary key codes or text.
public struct CommandTapPolicy: Sendable {
    private struct PendingTap: Sendable {
        let keyDownCount: UInt32
        let eligibleAtPress: Bool
    }

    private var pending: [CommandSide: PendingTap] = [:]

    public init() {}

    /// Returns a side only when its press/release pair contains no other
    /// key-down activity, no other Command key, and no non-Command modifier.
    public mutating func flagsChanged(
        side: CommandSide,
        isPressed: Bool,
        modifiers: ModifierSnapshot,
        keyDownCount: UInt32,
        anotherCommandHeld: Bool
    ) -> CommandSide? {
        if isPressed {
            if anotherCommandHeld {
                pending.removeAll()
            }
            pending[side] = PendingTap(
                keyDownCount: keyDownCount,
                eligibleAtPress: !modifiers.hasNonCommandModifier
                    && !anotherCommandHeld
            )
            return nil
        }

        guard let tap = pending.removeValue(forKey: side) else { return nil }
        guard tap.eligibleAtPress,
              !modifiers.hasNonCommandModifier,
              !anotherCommandHeld,
              tap.keyDownCount == keyDownCount
        else { return nil }
        return side
    }

    public mutating func reset() { pending.removeAll() }
}
