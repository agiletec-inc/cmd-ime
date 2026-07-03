import XCTest
import Carbon.HIToolbox
@testable import CmdIMESwift

final class InputSourceSwitcherTests: XCTestCase {

    func testShouldSwitchViaTIS_TrueForEisuAndKana() {
        XCTAssertTrue(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 102))
        XCTAssertTrue(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 104))
    }

    func testShouldSwitchViaTIS_FalseForOtherKeyCodes() {
        // A sampling of other outputs that must keep using the old
        // CGEvent.post remap path unchanged.
        XCTAssertFalse(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 0))
        XCTAssertFalse(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 53))
        XCTAssertFalse(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 999))
        XCTAssertFalse(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 103))
        XCTAssertFalse(InputSourceSwitcher.shouldSwitchViaTIS(outputKeyCode: 105))
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
