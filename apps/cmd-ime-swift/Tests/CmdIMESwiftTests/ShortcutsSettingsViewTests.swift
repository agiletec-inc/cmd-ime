import XCTest
@testable import CmdIMESwift

@MainActor
final class ShortcutsSettingsViewTests: XCTestCase {

    func testLaterRowWithSameInputAsEarlierEnabledRowIsShadowed() {
        let mappings = [
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 102)),
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
        ]

        XCTAssertFalse(ShortcutsSettingsView.isShadowed(mappings, at: 0))
        XCTAssertTrue(ShortcutsSettingsView.isShadowed(mappings, at: 1))
    }

    func testDifferentInputsAreNotShadowed() {
        let mappings = [
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 102)),
            KeyMapping(input: KeyboardShortcut(keyCode: 55), output: KeyboardShortcut(keyCode: 104))
        ]

        XCTAssertFalse(ShortcutsSettingsView.isShadowed(mappings, at: 1))
    }

    func testDisabledEarlierRowDoesNotShadow() {
        let mappings = [
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 102), enable: false),
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
        ]

        XCTAssertFalse(ShortcutsSettingsView.isShadowed(mappings, at: 1))
    }

    func testDisabledLaterRowIsNotFlaggedAsShadowed() {
        // A disabled row is simply off, not "shadowed" — the warning is only
        // meaningful for a row that would otherwise fire.
        let mappings = [
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 102)),
            KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104), enable: false)
        ]

        XCTAssertFalse(ShortcutsSettingsView.isShadowed(mappings, at: 1))
    }
}
