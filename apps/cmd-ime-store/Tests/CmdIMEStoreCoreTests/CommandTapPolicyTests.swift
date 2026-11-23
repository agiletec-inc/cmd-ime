import XCTest
@testable import CmdIMEStoreCore

final class CommandTapPolicyTests: XCTestCase {
    func testCommandSidesUsePhysicalMacKeyCodes() {
        XCTAssertEqual(CommandSide.left.keyCode, 55)
        XCTAssertEqual(CommandSide.right.keyCode, 54)
    }

    func testBareLeftCommandTapIsAccepted() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: true, modifiers: .command, keyDownCount: 10,
            anotherCommandHeld: false
        ))
        XCTAssertEqual(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: [], keyDownCount: 10,
            anotherCommandHeld: false
        ), .left)
    }

    func testBareRightCommandTapIsAccepted() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .right, isPressed: true, modifiers: .command, keyDownCount: 20,
            anotherCommandHeld: false
        ))
        XCTAssertEqual(policy.flagsChanged(
            side: .right, isPressed: false, modifiers: [], keyDownCount: 20,
            anotherCommandHeld: false
        ), .right)
    }

    func testCommandCChordIsRejectedWhenKeyDownCounterChanges() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: true, modifiers: .command, keyDownCount: 30,
            anotherCommandHeld: false
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: [], keyDownCount: 31,
            anotherCommandHeld: false
        ))
    }

    func testOtherCommandHeldRejectsTap() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: true, modifiers: .command, keyDownCount: 49,
            anotherCommandHeld: false
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .right, isPressed: true, modifiers: .command, keyDownCount: 50,
            anotherCommandHeld: true
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .right, isPressed: false, modifiers: .command, keyDownCount: 50,
            anotherCommandHeld: true
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: [], keyDownCount: 50,
            anotherCommandHeld: false
        ))
    }

    func testNonCommandModifierRejectsTap() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: true, modifiers: [.command, .shift], keyDownCount: 60,
            anotherCommandHeld: false
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: [], keyDownCount: 60,
            anotherCommandHeld: false
        ))
    }

    func testModifierPressedWhileCommandHeldRejectsTap() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: true, modifiers: .command, keyDownCount: 70,
            anotherCommandHeld: false
        ))
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: .shift, keyDownCount: 70,
            anotherCommandHeld: false
        ))
    }

    func testUnmatchedReleaseDoesNothing() {
        var policy = CommandTapPolicy()
        XCTAssertNil(policy.flagsChanged(
            side: .right, isPressed: false, modifiers: [], keyDownCount: 80,
            anotherCommandHeld: false
        ))
    }

    func testResetDiscardsPendingTap() {
        var policy = CommandTapPolicy()
        _ = policy.flagsChanged(
            side: .left, isPressed: true, modifiers: .command, keyDownCount: 90,
            anotherCommandHeld: false
        )
        policy.reset()
        XCTAssertNil(policy.flagsChanged(
            side: .left, isPressed: false, modifiers: [], keyDownCount: 90,
            anotherCommandHeld: false
        ))
    }
}
