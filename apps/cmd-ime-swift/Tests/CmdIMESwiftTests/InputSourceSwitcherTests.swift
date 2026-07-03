import XCTest
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
}
