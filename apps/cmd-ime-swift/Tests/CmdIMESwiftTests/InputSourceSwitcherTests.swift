import XCTest
import Carbon.HIToolbox
@testable import CmdIMESwift

final class InputSourceSwitcherTests: XCTestCase {

    func testIsInputSourceSwitchKey_TrueForEisuAndKana() {
        XCTAssertTrue(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 102))
        XCTAssertTrue(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 104))
    }

    func testIsInputSourceSwitchKey_FalseForOtherKeyCodes() {
        // A sampling of other outputs that must keep using the plain
        // CGEvent-post remap path unchanged.
        XCTAssertFalse(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 0))
        XCTAssertFalse(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 53))
        XCTAssertFalse(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 999))
        XCTAssertFalse(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 103))
        XCTAssertFalse(InputSourceSwitcher.isInputSourceSwitchKey(outputKeyCode: 105))
    }

    func testTISSwitchAppBundleIDs_ContainsAffinity() {
        XCTAssertTrue(InputSourceSwitcher.tisSwitchAppBundleIDs.contains("com.canva.affinity"))
    }

    /// Regression test for the v2.4.7 bug where the kana switch selected the
    /// 50-on Kana Palette (a palette-category input source with language
    /// "ja"), opening a floating palette window. The picked source must be a
    /// keyboard input source; when a Japanese IME is enabled, it must be the
    /// Hiragana input mode.
    func testJapaneseInputSource_NeverPicksPalette() throws {
        guard let source = InputSourceSwitcher.japaneseInputSource() else {
            throw XCTSkip("No enabled Japanese keyboard input source on this machine.")
        }

        XCTAssertEqual(property(source, kTISPropertyInputSourceCategory),
                       kTISCategoryKeyboardInputSource as String)
        XCTAssertEqual(property(source, kTISPropertyInputModeID),
                       "com.apple.inputmethod.Japanese")
    }

    private func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
