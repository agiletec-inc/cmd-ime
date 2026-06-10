import XCTest
@testable import CmdIMESwift

final class KeyEventTests: XCTestCase {

    var keyEvent: KeyEvent!

    override func setUp() {
        super.setUp()
        keyEvent = KeyEvent()
        // Reset global state
        keyMappingList = []
        shortcutList = [:]
    }

    override func tearDown() {
        keyEvent = nil
        keyMappingList = []
        shortcutList = [:]
        super.tearDown()
    }

    func testKeyDown_PassesThrough_WhenNoMapping() {
        // Setup: No mappings
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!

        let result = keyEvent.keyDown(event)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.takeRetainedValue().getIntegerValueField(.keyboardEventKeycode), 0)
    }

    func testKeyDown_RemapsEvent_WhenMappingExists() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.takeRetainedValue().getIntegerValueField(.keyboardEventKeycode), 104)
    }

    func testKeyDown_SwallowsEvent_WhenMappedToDisable() {
        // Setup: Map Command_L (55) to Disable (999)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 999)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        XCTAssertNil(result)
    }

    func testKeyDown_NoMatch_WhenDifferentKey() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        // Press 'A' (keyCode 0) — no mapping
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!

        let result = keyEvent.keyDown(event)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.takeRetainedValue().getIntegerValueField(.keyboardEventKeycode), 0)
    }

    // MARK: - Tap recovery (#107: external monitor connect/disconnect)

    func testIsTapDisabled_TrueForSystemDisableTypes() {
        XCTAssertTrue(CGEventType.tapDisabledByTimeout.isTapDisabled)
        XCTAssertTrue(CGEventType.tapDisabledByUserInput.isTapDisabled)
    }

    func testIsTapDisabled_FalseForNormalEventTypes() {
        XCTAssertFalse(CGEventType.keyDown.isTapDisabled)
        XCTAssertFalse(CGEventType.keyUp.isTapDisabled)
        XCTAssertFalse(CGEventType.flagsChanged.isTapDisabled)
    }

    func testShouldRebuildTap_TrueForDisplayAddRemoveAndModeChange() {
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: .addFlag))
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: .removeFlag))
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: .enabledFlag))
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: .disabledFlag))
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: .setModeFlag))
        // Real reconfiguration end-pass flags often arrive combined.
        XCTAssertTrue(keyEvent.shouldRebuildTap(for: [.addFlag, .setModeFlag]))
    }

    func testShouldRebuildTap_FalseForIrrelevantFlags() {
        XCTAssertFalse(keyEvent.shouldRebuildTap(for: []))
        XCTAssertFalse(keyEvent.shouldRebuildTap(for: .movedFlag))
        XCTAssertFalse(keyEvent.shouldRebuildTap(for: .mirrorFlag))
    }
}
