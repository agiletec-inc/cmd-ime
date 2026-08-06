import XCTest
@testable import CmdIMESwift

final class KeyEventTests: XCTestCase {

    var keyEvent: KeyEvent!
    var postedTaps: [KeyboardShortcut] = []
    var selectedInputSources: [String] = []

    override func setUp() {
        super.setUp()
        keyEvent = KeyEvent()
        // Capture synthesized modifier taps instead of posting system-wide events.
        postedTaps = []
        keyEvent.postModifierTap = { [weak self] in self?.postedTaps.append($0) }
        // Capture TIS selections instead of mutating real input-source state.
        selectedInputSources = []
        keyEvent.selectInputSourceAction = { [weak self] in self?.selectedInputSources.append($0) }
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

    // MARK: - Modifier tap gesture tracking
    //
    // modifierKeyDown/modifierKeyUp track per-modifier pending taps in
    // `pendingModifierTaps`; a release fires its mapping iff its keyCode is
    // still pending. Other modifiers held alongside (any press/release
    // order) must NOT cancel a tap — tapping ⌘ with Shift held still has to
    // switch the IME. A regular keyDown, mouse event, or media key cancels
    // all pending taps; a regular keyUp does not. Fired taps are captured
    // through the `postModifierTap` seam instead of hitting the system.

    private func modifierEvent(_ keyCode: CGKeyCode, flags: CGEventFlags = []) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
        event.flags = flags
        return event
    }

    func testModifierTap_Fires_OnLonePressAndRelease() {
        // Command_L (55) -> Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        XCTAssertEqual(keyEvent.pendingModifierTaps, [55], "press must be pending so the release can fire")

        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(postedTaps.count, 1)
        XCTAssertEqual(postedTaps.first?.keyCode, 104)
        XCTAssertTrue(keyEvent.pendingModifierTaps.isEmpty, "pending tap is consumed by the release")
    }

    func testModifierTap_Fires_WithShiftHeld_AndStripsResidualFlags() {
        // Shift held the whole time: ⇧ down -> ⌘ down -> ⌘ up. The tap must
        // still fire, and the synthesized Eisu must NOT carry the Shift flag
        // (the IME ignores Shift+英数).
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(56, flags: .maskShift))
        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: [.maskCommand, .maskShift]))
        _ = keyEvent.modifierKeyUp(modifierEvent(55, flags: .maskShift))

        XCTAssertEqual(postedTaps.count, 1, "a held sibling modifier must not cancel the ⌘ tap")
        XCTAssertEqual(postedTaps.first?.keyCode, 102)
        XCTAssertEqual(postedTaps.first?.flags, CGEventFlags(),
                       "residual held modifiers must be stripped from the synthesized tap")
    }

    func testModifierTap_Fires_WhenOtherModifierReleasedFirst() {
        // ⌘ down -> ⇧ down -> ⇧ up -> ⌘ up: the unrelated Shift release must
        // not consume or cancel the still-pending ⌘ tap.
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.modifierKeyDown(modifierEvent(56, flags: [.maskCommand, .maskShift]))
        _ = keyEvent.modifierKeyUp(modifierEvent(56, flags: .maskCommand))
        XCTAssertEqual(postedTaps.count, 0, "Shift has no mapping, so its release posts nothing")

        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(postedTaps.count, 1)
        XCTAssertEqual(postedTaps.first?.keyCode, 102)
    }

    func testModifierTap_EachModifierFiresIndependently() {
        // Hold Command_L, tap Command_R, release Command_L: both taps fire
        // their own mapping. Held siblings no longer cancel (that chord-cancel
        // behavior broke "switch even with other modifiers held").
        keyMappingList = [
            KeyMapping(input: KeyboardShortcut(keyCode: 55, flags: .maskCommand),
                       output: KeyboardShortcut(keyCode: 102)),
            KeyMapping(input: KeyboardShortcut(keyCode: 54, flags: .maskCommand),
                       output: KeyboardShortcut(keyCode: 104))
        ]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.modifierKeyDown(modifierEvent(54, flags: .maskCommand))
        _ = keyEvent.modifierKeyUp(modifierEvent(54, flags: .maskCommand))
        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(postedTaps.map(\.keyCode), [104, 102])
    }

    func testRegularKeyDown_CancelsAllPendingTaps() {
        // ⌘ down -> 'A' down -> ⌘ up is a shortcut, not a tap.
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.keyDown(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!)
        XCTAssertTrue(keyEvent.pendingModifierTaps.isEmpty,
                      "a regular keystroke mid-hold must cancel pending modifier taps")

        _ = keyEvent.modifierKeyUp(modifierEvent(55))
        XCTAssertTrue(postedTaps.isEmpty)
    }

    func testRegularKeyUp_DoesNotCancelPendingTap() {
        // Fast-typing commit: 'A' down -> ⌘ down -> 'A' up -> ⌘ up. The
        // up-stroke of the character typed just before the ⌘ press must not
        // cancel the tap, or committing a conversion with ⌘ misfires.
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.keyDown(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!)
        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.keyUp(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)!)
        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(postedTaps.map(\.keyCode), [102])
    }

    // MARK: - Output mechanism selection (#multilang): a mapping with
    // outputInputSourceID set selects that TIS source instead of posting a
    // key; a plain key-code output (Eisu/Kana/remap) keeps posting as before.

    func testModifierTap_SelectsInputSource_WhenMappingHasOutputInputSourceID() {
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let mapping = KeyMapping(
            input: input, output: KeyboardShortcut(), outputInputSourceID: "com.apple.inputmethod.SCIM.ITABC"
        )
        keyMappingList = [mapping]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(selectedInputSources, ["com.apple.inputmethod.SCIM.ITABC"])
        XCTAssertTrue(postedTaps.isEmpty, "an input-source mapping must not also post a key")
    }

    func testModifierTap_PostsKey_WhenMappingHasNoOutputInputSourceID() {
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 102)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertEqual(postedTaps.map(\.keyCode), [102])
        XCTAssertTrue(selectedInputSources.isEmpty, "a key-post mapping must not also select an input source")
    }

    func testModifierTap_DoesNotPost_WhenMappedToDisable() {
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 999)
        keyMappingList = [KeyMapping(input: input, output: output)]
        keyMappingListToShortcutList()

        _ = keyEvent.modifierKeyDown(modifierEvent(55, flags: .maskCommand))
        _ = keyEvent.modifierKeyUp(modifierEvent(55))

        XCTAssertTrue(postedTaps.isEmpty)
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
