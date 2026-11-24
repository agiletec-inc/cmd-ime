import ApplicationServices
import XCTest
@testable import CmdIMESwift

final class SmartFocusTests: XCTestCase {
    private let initial = SmartFocusRequests.Target(pid: 100, bundleID: "example.browser")
    private let relaunched = SmartFocusRequests.Target(pid: 200, bundleID: "example.browser")
    private let other = SmartFocusRequests.Target(pid: 300, bundleID: "example.editor")

    func testOnlyLatestFocusRequestRunsAfterInFlightRead() throws {
        var requests = SmartFocusRequests()
        requests.update(target: initial)
        let first = try XCTUnwrap(requests.begin())

        requests.update(target: relaunched)
        requests.update(target: other)
        XCTAssertNil(requests.begin())
        XCTAssertFalse(requests.isCurrent(first))

        requests.finish()
        let latest = try XCTUnwrap(requests.begin())
        XCTAssertEqual(latest.target, other)
        XCTAssertTrue(requests.isCurrent(latest))
        requests.finish()
        XCTAssertNil(requests.begin())
    }

    func testSameAppFocusChangeInvalidatesReadAndRefreshesAfterRegistration() throws {
        var requests = SmartFocusRequests()
        requests.update(target: initial)
        let registration = try XCTUnwrap(requests.begin())

        requests.update(target: initial)
        let latest = try XCTUnwrap(requests.beginRead(after: registration))
        XCTAssertFalse(requests.isCurrent(registration))
        XCTAssertTrue(requests.isCurrent(latest))
        XCTAssertNil(requests.begin())
        requests.finish()
        XCTAssertNil(requests.begin())
    }

    func testDisablingSmartModeInvalidatesReadEvenIfReenabledForSameApp() throws {
        var requests = SmartFocusRequests()
        requests.update(target: initial)
        let read = try XCTUnwrap(requests.begin())

        requests.update(target: nil)
        XCTAssertNil(requests.beginRead(after: read))
        requests.update(target: initial)
        XCTAssertFalse(requests.isCurrent(read))
        XCTAssertNil(requests.begin())

        requests.finish()
        XCTAssertTrue(requests.isCurrent(try XCTUnwrap(requests.begin())))
    }

    func testMetadataSkipsUnsupportedAttributesAndTreatsMessagingFailureAsUnknown() throws {
        var unsupported = AXError.attributeUnsupported
        var timeout = AXError.cannotComplete
        let missing = try XCTUnwrap(AXValueCreate(.axError, &unsupported))
        let failed = try XCTUnwrap(AXValueCreate(.axError, &timeout))

        XCTAssertEqual(AutoSwitcher.classifyFieldMetadata([missing, "Search" as NSString]), false)
        XCTAssertNil(AutoSwitcher.classifyFieldMetadata([failed, "Search" as NSString]))
        XCTAssertEqual(AutoSwitcher.classifyFieldMetadata([failed, "Email address" as NSString]), true)
    }
}
