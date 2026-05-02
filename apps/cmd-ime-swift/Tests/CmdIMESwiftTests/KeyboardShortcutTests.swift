import XCTest
@testable import CmdIMESwift

final class KeyboardShortcutTests: XCTestCase {

    func testDictionaryRoundTrip() {
        let original = KeyboardShortcut(keyCode: 12, flags: [.maskCommand, .maskShift])
        let restored = KeyboardShortcut(dictionary: original.toDictionary())
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.keyCode, 12)
        XCTAssertEqual(restored?.flags.rawValue,
                       (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
    }

    func testCommandIgnoredOnCommandKeyItself() {
        // Holding Command_L (55) shouldn't report "Command is down" — that
        // would make modifier-only mappings impossible to express.
        let leftCommand = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        XCTAssertFalse(leftCommand.isCommandDown())

        let aWithCommand = KeyboardShortcut(keyCode: 0, flags: .maskCommand)
        XCTAssertTrue(aWithCommand.isCommandDown())
    }

    func testShiftIgnoredOnShiftKeyItself() {
        let leftShift = KeyboardShortcut(keyCode: 56, flags: .maskShift)
        XCTAssertFalse(leftShift.isShiftDown())

        let aWithShift = KeyboardShortcut(keyCode: 0, flags: .maskShift)
        XCTAssertTrue(aWithShift.isShiftDown())
    }

    func testIsCoverRequiresAllExpectedModifiers() {
        // Mapping wants Cmd+Shift+A; pressing only Cmd+A must not match.
        let expected = KeyboardShortcut(keyCode: 0, flags: [.maskCommand, .maskShift])
        let pressedCmdOnly = KeyboardShortcut(keyCode: 0, flags: .maskCommand)
        XCTAssertFalse(pressedCmdOnly.isCover(expected))

        // Pressing Cmd+Shift+A matches Cmd+Shift+A.
        let pressedBoth = KeyboardShortcut(keyCode: 0, flags: [.maskCommand, .maskShift])
        XCTAssertTrue(pressedBoth.isCover(expected))

        // Extra modifiers on the actual press are still considered covering.
        let pressedExtra = KeyboardShortcut(keyCode: 0, flags: [.maskCommand, .maskShift, .maskAlternate])
        XCTAssertTrue(pressedExtra.isCover(expected))
    }

    func testToStringRendersCommonKeys() {
        XCTAssertEqual(KeyboardShortcut(keyCode: 102).toString(), "英数")
        XCTAssertEqual(KeyboardShortcut(keyCode: 104).toString(), "かな")
        XCTAssertEqual(KeyboardShortcut(keyCode: 0, flags: .maskCommand).toString(), "⌘A")
        XCTAssertEqual(KeyboardShortcut(keyCode: 0, flags: [.maskCommand, .maskShift]).toString(), "⌘⇧A")
    }
}
