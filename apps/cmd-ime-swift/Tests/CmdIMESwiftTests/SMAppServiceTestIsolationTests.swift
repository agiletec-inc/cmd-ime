import XCTest

/// Regression guard for the incident where a test called the real
/// `SMAppService.mainApp` API and registered the `xctest` test-runner binary
/// itself as a login item on the developer's Mac (bootstrap() ->
/// setLaunchAtStartup(true) -> SMAppService.mainApp.register()). Every test
/// must go through the injectable `LoginItemService` seam (see
/// toggleLaunchAtStartup.swift / FakeLoginItemService.swift) instead.
final class SMAppServiceTestIsolationTests: XCTestCase {
    func testNoTestFileReferencesTheRealSMAppServiceMainApp() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let contents = try FileManager.default.contentsOfDirectory(
            at: testsDirectory, includingPropertiesForKeys: nil
        )
        let swiftFiles = contents.filter { $0.pathExtension == "swift" }
        XCTAssertFalse(swiftFiles.isEmpty, "sanity check: the test directory listing must not be empty")

        for file in swiftFiles {
            // FakeLoginItemService itself is a legitimate SMAppService.Status
            // consumer (it stands in for the real type's status enum), and
            // this file's own doc comment names the hazard string it scans
            // for — neither is an actual live call.
            guard file.lastPathComponent != "FakeLoginItemService.swift",
                  file.lastPathComponent != "SMAppServiceTestIsolationTests.swift" else { continue }
            let contents = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(contents.contains("SMAppService.mainApp"),
                           "\(file.lastPathComponent) references the real SMAppService.mainApp — " +
                           "inject FakeLoginItemService instead (see AppSettingsTests.swift)")
        }
    }
}
