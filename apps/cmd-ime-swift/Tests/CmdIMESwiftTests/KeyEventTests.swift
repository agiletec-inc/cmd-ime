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
        // Setup: Map Command_L (55) to Escape (53) — a non-Eisu/Kana output,
        // so this stays on the plain CGEvent-post remap path.
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 53)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.takeRetainedValue().getIntegerValueField(.keyboardEventKeycode), 53)
    }

    // MARK: - Eisu/Kana output swallows the event (TIS switch instead of CGEvent.post)

    func testKeyDown_SwallowsEvent_WhenMappedToKana() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        // Some apps don't route synthesized Eisu/Kana key events through the
        // input context, so cmd-ime switches via TIS and swallows the event
        // rather than posting a synthesized key.
        XCTAssertNil(result)
    }

    func testKeyDown_SwallowsEvent_WhenMappedToEisu() {
        // Setup: Map Command_R (54) to Eisu (102)
        let input = KeyboardShortcut(keyCode: 54, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        XCTAssertNil(result)
    }

    func testKeyUp_SwallowsEvent_WhenMappedToKana() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)!
        event.flags = .maskCommand

        let result = keyEvent.keyUp(event)

        // keyUp must not switch a second time — it just swallows silently.
        XCTAssertNil(result)
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
