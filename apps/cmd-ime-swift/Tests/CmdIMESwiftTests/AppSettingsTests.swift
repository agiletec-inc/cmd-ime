import XCTest
@testable import CmdIMESwift

@MainActor
final class AppSettingsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "test.cmdime.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        // Reset legacy globals KeyEvent reads.
        keyMappingList = []
        shortcutList = [:]
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        try await super.tearDown()
    }

    func testMigratesLegacyLaunchAtStartupKey() {
        defaults.set(1, forKey: "lunchAtStartup")  // legacy typo

        _ = AppSettings(defaults: defaults)

        XCTAssertEqual(defaults.object(forKey: "launchAtStartup") as? Int, 1)
        XCTAssertNil(defaults.object(forKey: "lunchAtStartup"))
    }

    func testMigratesLegacyCheckUpdateAtLaunchKey() {
        defaults.set(0, forKey: "checkUpdateAtlaunch")  // legacy lower-case "l"

        _ = AppSettings(defaults: defaults)

        XCTAssertEqual(defaults.object(forKey: "checkUpdateAtLaunch") as? Int, 0)
        XCTAssertNil(defaults.object(forKey: "checkUpdateAtlaunch"))
    }

    func testLoadsDefaultKeyMappingsWhenNoneStored() {
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.keyMappings.count, 2)
        XCTAssertEqual(settings.keyMappings[0].input.keyCode, 55)   // Cmd_L
        XCTAssertEqual(settings.keyMappings[0].output.keyCode, 102) // 英数
        XCTAssertEqual(settings.keyMappings[1].input.keyCode, 54)   // Cmd_R
        XCTAssertEqual(settings.keyMappings[1].output.keyCode, 104) // かな
    }

    func testKeyMappingMutationPersistsAndUpdatesGlobals() {
        let settings = AppSettings(defaults: defaults)
        let initialCount = settings.keyMappings.count

        settings.addKeyMapping()
        XCTAssertEqual(settings.keyMappings.count, initialCount + 1)

        // didSet fires synchronously; legacy globals must be updated.
        XCTAssertEqual(keyMappingList.count, initialCount + 1)

        // Persisted to UserDefaults under the canonical key.
        let stored = defaults.object(forKey: "mappings") as? [[AnyHashable: Any]]
        XCTAssertEqual(stored?.count, initialCount + 1)
    }

    func testRemoveKeyMappingPersistsRemoval() {
        let settings = AppSettings(defaults: defaults)
        settings.removeKeyMapping(at: 0)

        XCTAssertEqual(settings.keyMappings.count, 1)
        XCTAssertEqual(keyMappingList.count, 1)
    }

    func testExclusionMutationsPropagateToGlobals() {
        let settings = AppSettings(defaults: defaults)
        let app = AppData(name: "Code", id: "com.microsoft.VSCode")

        settings.addExclusion(app)

        XCTAssertEqual(settings.exclusionApps.count, 1)
        XCTAssertEqual(exclusionAppsList.count, 1)
        XCTAssertEqual(exclusionAppsDict["com.microsoft.VSCode"], "Code")

        // Adding the same app twice is a no-op.
        settings.addExclusion(app)
        XCTAssertEqual(settings.exclusionApps.count, 1)

        settings.removeExclusion(at: 0)
        XCTAssertEqual(settings.exclusionApps.count, 0)
        XCTAssertEqual(exclusionAppsList.count, 0)
        XCTAssertNil(exclusionAppsDict["com.microsoft.VSCode"])
    }
}
