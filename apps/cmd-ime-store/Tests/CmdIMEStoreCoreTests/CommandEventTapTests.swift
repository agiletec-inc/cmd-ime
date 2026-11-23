import XCTest
@testable import CmdIMEStoreCore

final class CommandEventTapTests: XCTestCase {
    func testStartDoesNotRequestPermissionAutomatically() {
        var requestCount = 0
        let tap = CommandEventTap(
            accessCheck: { false },
            accessRequest: { requestCount += 1; return false },
            onTap: { _ in XCTFail("No tap should be created without permission") }
        )

        XCTAssertEqual(tap.start(), .permissionRequired)
        XCTAssertEqual(requestCount, 0)
    }

    func testExplicitRequestInvokesPermissionRequest() {
        var requestCount = 0
        let tap = CommandEventTap(
            accessCheck: { false },
            accessRequest: { requestCount += 1; return false },
            onTap: { _ in XCTFail("No tap should be created without permission") }
        )

        XCTAssertEqual(tap.requestAccessAndStart(), .permissionRequired)
        XCTAssertEqual(requestCount, 1)
    }
}
