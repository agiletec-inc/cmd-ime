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

    // MARK: - Eisu/Kana output passes the remapped key through so the IME
    // switches its internal Hiragana/direct mode (correct for Google/ATOK).
    // The synthesized key is posted with a real HID source (see postEvent).

    func testKeyDown_PassesKanaKeyThrough() {
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

    func testKeyDown_PassesEisuKeyThrough() {
        let input = KeyboardShortcut(keyCode: 54, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        event.flags = .maskCommand

        let result = keyEvent.keyDown(event)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.takeRetainedValue().getIntegerValueField(.keyboardEventKeycode), 102)
    }

    func testKeyUp_PassesKanaKeyThrough() {
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)!
        event.flags = .maskCommand

        let result = keyEvent.keyUp(event)

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

    // MARK: - Lone-modifier gesture tracking (chord false-fire bug)
    //
    // modifierKeyDown/modifierKeyUp track a single "lone press in flight"
    // keyCode in `keyEvent.keyCode`, backed by `downModifierKeyCodes` (the
    // set of modifier keyCodes currently physically held). modifierKeyDown
    // arms the lone-press gesture only when the incoming key is the sole
    // held modifier; otherwise (a chord, or a re-press while a sibling is
    // still held) it cancels the gesture instead of overwriting the slot.
    // modifierKeyUp only ever fires its remap when `keyEvent.keyCode` still
    // equals the released key, so asserting on that tracked value is the
    // observable proxy for "will fire on release" — the actual remap is
    // posted to the system as a side effect (KeyboardShortcut.postEvent),
    // which isn't something a unit test can intercept.

    func testModifierKeyDown_TracksLoneModifierPress() {
        let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        downEvent.flags = .maskCommand

        _ = keyEvent.modifierKeyDown(downEvent)

        XCTAssertEqual(keyEvent.keyCode, 55)
    }

    func testModifierKeyDownThenUp_FiresRemap_OnLonePressAndRelease() {
        // Command_L (55) alone -> Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        downEvent.flags = .maskCommand
        _ = keyEvent.modifierKeyDown(downEvent)
        XCTAssertEqual(keyEvent.keyCode, 55, "lone press must be tracked so the matching release can fire")

        let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        let result = keyEvent.modifierKeyUp(upEvent)

        XCTAssertNotNil(result)
        XCTAssertNil(keyEvent.keyCode, "tracking slot is cleared after release")
    }

    func testModifierChord_CancelsGesture_SoNeitherReleaseFires() {
        // Hold Left Command (55), then Right Command (54) while it's still held.
        let leftDown = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        leftDown.flags = .maskCommand
        _ = keyEvent.modifierKeyDown(leftDown)
        XCTAssertEqual(keyEvent.keyCode, 55)

        let rightDown = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        rightDown.flags = [.maskCommand]
        _ = keyEvent.modifierKeyDown(rightDown)

        // The chord must cancel tracking for BOTH keys, not overwrite the slot
        // with 54 (which would make Right Command's release fire alone).
        XCTAssertNil(keyEvent.keyCode, "second modifier down while one is tracked must cancel, not overwrite")

        let rightUp = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        _ = keyEvent.modifierKeyUp(rightUp)
        XCTAssertNil(keyEvent.keyCode, "cancelled gesture must not fire on Right Command's release")

        // Left Command is still physically held in this scenario, but its
        // eventual release must not retroactively fire either.
        let leftUp = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        _ = keyEvent.modifierKeyUp(leftUp)
        XCTAssertNil(keyEvent.keyCode, "cancelled gesture must not fire on Left Command's release either")
    }

    func testModifierChord_RepressAfterReleaseWhileOtherStillHeld_DoesNotFire() {
        // Regression for the hole in the first chord fix: the tracked-keyCode
        // slot alone can't tell "nothing else is held" from "something else
        // is still held but its slot got cancelled". downModifierKeyCodes
        // fixes that by counting actual held keys instead.
        //
        // Hold Left Command (55) -> press Right Command (54, cancels slot) ->
        // release Right Command (no fire) -> press Right Command again while
        // Left Command is STILL held -> release Right Command again. Before
        // the fix, the slot was nil after the first Right Command release, so
        // the second Right Command press would re-arm it with 54 and its
        // release would falsely fire the lone-press mapping.
        let leftDown = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        leftDown.flags = .maskCommand
        _ = keyEvent.modifierKeyDown(leftDown)
        XCTAssertEqual(keyEvent.keyCode, 55)

        let rightDown = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        rightDown.flags = [.maskCommand]
        _ = keyEvent.modifierKeyDown(rightDown)
        XCTAssertNil(keyEvent.keyCode)

        let rightUp = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        _ = keyEvent.modifierKeyUp(rightUp)
        XCTAssertNil(keyEvent.keyCode)

        let rightDownAgain = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        rightDownAgain.flags = [.maskCommand]
        _ = keyEvent.modifierKeyDown(rightDownAgain)
        XCTAssertNil(keyEvent.keyCode,
                      "re-pressing a modifier while a sibling is still held must not re-arm the lone-press gesture")

        let rightUpAgain = CGEvent(keyboardEventSource: nil, virtualKey: 54, keyDown: true)!
        let result = keyEvent.modifierKeyUp(rightUpAgain)
        XCTAssertNotNil(result)
        XCTAssertNil(keyEvent.keyCode, "must not fire — Left Command is still physically held")

        // Left Command's eventual release must not retroactively fire either.
        let leftUp = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        _ = keyEvent.modifierKeyUp(leftUp)
        XCTAssertNil(keyEvent.keyCode, "cancelled gesture must not fire on Left Command's release either")
    }

    func testRegularKeyDown_CancelsInFlightModifierGesture() {
        // Existing behavior: keyDown()/keyUp() unconditionally reset keyCode,
        // so a regular keystroke mid-hold cancels the lone-press gesture.
        let modifierDown = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        modifierDown.flags = .maskCommand
        _ = keyEvent.modifierKeyDown(modifierDown)
        XCTAssertEqual(keyEvent.keyCode, 55)

        let regularKey = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        _ = keyEvent.keyDown(regularKey)

        XCTAssertNil(keyEvent.keyCode, "a regular keystroke mid-hold must cancel the lone-modifier gesture")
    }

    // MARK: - Media-key remap keyUp (stuck-key bug)
    //
    // Synthesizes an NX_SYSDEFINED CGEvent the same way AppKit does for media
    // keys, by round-tripping through NSEvent (there's no public CGEvent
    // constructor for this event type).

    private func makeMediaKeyEvent(rawKeyCode: Int32, keyDown: Bool) -> MediaKeyEvent? {
        let keyState = keyDown ? 0xa : 0xb
        let data1 = (Int(rawKeyCode) << 16) | (keyState << 8)
        guard let nsEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: 0
        ), let cgEvent = nsEvent.cgEvent else {
            return nil
        }
        return MediaKeyEvent(cgEvent)
    }

    func testMediaKeyUp_PostsMatchingKeyUp_WhenRemapped() {
        // Map the Play media key to Escape (53) — a plain remap output.
        let mediaKeyCode = CGKeyCode(1000 + UInt16(NX_KEYTYPE_PLAY))
        let input = KeyboardShortcut(keyCode: mediaKeyCode)
        let output = KeyboardShortcut(keyCode: 53)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        guard let mediaKeyEvent = makeMediaKeyEvent(rawKeyCode: NX_KEYTYPE_PLAY, keyDown: false) else {
            XCTFail("failed to synthesize NX_SYSDEFINED CGEvent for this platform")
            return
        }

        // Before the fix, mediaKeyUp always passed the raw event through
        // regardless of the mapping, so this would return non-nil.
        let result = keyEvent.mediaKeyUp(mediaKeyEvent)

        XCTAssertNil(result, "a remapped media key-up must be swallowed after posting the synthesized keyUp")
    }

    func testMediaKeyUp_PassesThrough_WhenNoMapping() {
        guard let mediaKeyEvent = makeMediaKeyEvent(rawKeyCode: NX_KEYTYPE_PLAY, keyDown: false) else {
            XCTFail("failed to synthesize NX_SYSDEFINED CGEvent for this platform")
            return
        }

        let result = keyEvent.mediaKeyUp(mediaKeyEvent)

        XCTAssertNotNil(result)
    }
}
