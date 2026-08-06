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

    func testQuitOnCommandQDefaultsToOff() {
        let settings = AppSettings(defaults: defaults)

        // Default is off: ⌘Q keeps the agent in the menu bar (only closes the window).
        XCTAssertFalse(settings.quitOnCommandQ)
    }

    func testQuitOnCommandQLoadsStoredValue() {
        defaults.set(1, forKey: "quitOnCommandQ")

        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.quitOnCommandQ)
    }

    func testQuitOnCommandQPersistsOnChange() {
        let settings = AppSettings(defaults: defaults)

        settings.quitOnCommandQ = true
        XCTAssertEqual(defaults.object(forKey: "quitOnCommandQ") as? Int, 1)

        settings.quitOnCommandQ = false
        XCTAssertEqual(defaults.object(forKey: "quitOnCommandQ") as? Int, 0)
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

    func testAddedKeyMappingStartsDisabled() {
        // A bare KeyMapping()'s default shortcut is keyCode 0 ("A"), so the
        // new row must not be live until the user configures it.
        let settings = AppSettings(defaults: defaults)

        settings.addKeyMapping()

        XCTAssertFalse(settings.keyMappings.last?.enable ?? true)
    }

    func testUpdateKeyMappingEnablesOnlyOnceBothInputAndOutputAreSet() {
        let settings = AppSettings(defaults: defaults)
        settings.addKeyMapping()
        let index = settings.keyMappings.count - 1

        settings.updateKeyMapping(at: index, input: KeyboardShortcut(keyCode: 54))
        XCTAssertFalse(settings.keyMappings[index].enable, "still missing an output")

        settings.updateKeyMapping(at: index, output: KeyboardShortcut(keyCode: 102))
        XCTAssertTrue(settings.keyMappings[index].enable, "both sides are now set")
    }

    func testRemoveKeyMappingPersistsRemoval() {
        let settings = AppSettings(defaults: defaults)
        settings.removeKeyMapping(at: 0)

        XCTAssertEqual(settings.keyMappings.count, 1)
        XCTAssertEqual(keyMappingList.count, 1)
    }

    func testStoredEmptyKeyMappingsArraySurvivesReloadAsEmpty() {
        // A stored empty array is authoritative — the user removed every
        // mapping on purpose and must not get the factory defaults back.
        defaults.set([[AnyHashable: Any]](), forKey: "mappings")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.keyMappings.count, 0)
    }

    func testMissingKeyMappingsKeyStillYieldsDefaults() {
        // No "mappings" key at all (fresh install) still yields the two
        // factory defaults, distinguishing "never written" from "emptied".
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.keyMappings.count, 2)
    }

    func testDuplicateExclusionAppEntriesAreDedupedKeepingFirst() {
        // Two stored entries share the same id but differ in name so we can
        // tell which one survives de-duping.
        let first = AppData(name: "First", id: "com.example.app")
        let second = AppData(name: "Second", id: "com.example.app")
        defaults.set([first.toDictionary(), second.toDictionary()], forKey: "exclusionApps")

        // Must not crash (Dictionary(uniqueKeysWithValues:) would trap on
        // the duplicate id) and must keep the first occurrence.
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.exclusionApps.count, 1)
        XCTAssertEqual(settings.exclusionApps[0].name, "First")
        XCTAssertEqual(exclusionAppsDict["com.example.app"], "First")
    }

    func testBootstrapWithStoredTrueAndServiceNotFoundRegistersInstead() {
        // Never-registered case (.notFound, the real status a bare
        // `swift test` process reported before this test used a fake — see
        // FakeLoginItemService): bootstrap() must honor the stored intent
        // and attempt to register, NOT flip the toggle off.
        let fakeService = FakeLoginItemService(status: .notFound)
        defaults.set(1, forKey: "launchAtStartup")
        let settings = AppSettings(defaults: defaults, loginItemService: fakeService)
        XCTAssertTrue(settings.launchAtStartup, "precondition: stored value loaded as on")

        settings.bootstrap()

        XCTAssertTrue(settings.launchAtStartup, "never-registered case must honor stored intent, not follow OS off")
        XCTAssertEqual(defaults.object(forKey: "launchAtStartup") as? Int, 1)
        XCTAssertEqual(fakeService.registerCallCount, 1, "bootstrap() must register the never-registered case")
    }

    func testBootstrapWithStoredTrueAndRequiresApprovalFollowsOSStateInstead() {
        // Registered but user-disabled (or not yet approved) in System
        // Settings -> Login Items: bootstrap() must defer to the OS state,
        // not force re-registration behind the user's back. This branch was
        // previously unreachable from a real `swift test` process (see
        // git history) and had no automated coverage.
        let fakeService = FakeLoginItemService(status: .requiresApproval)
        defaults.set(1, forKey: "launchAtStartup")
        let settings = AppSettings(defaults: defaults, loginItemService: fakeService)
        XCTAssertTrue(settings.launchAtStartup, "precondition: stored value loaded as on")

        settings.bootstrap()

        XCTAssertFalse(settings.launchAtStartup, "requiresApproval case must follow the OS state, not stored intent")
        XCTAssertEqual(defaults.object(forKey: "launchAtStartup") as? Int, 0)
        XCTAssertEqual(fakeService.registerCallCount, 0, "must not force re-registration behind the user's back")
    }

    func testExclusionMutationsPropagateToGlobals() {
        let settings = AppSettings(defaults: defaults)
        let app = AppData(name: "Code", id: "com.microsoft.VSCode")

        settings.addExclusion(app)

        XCTAssertEqual(settings.exclusionApps.count, 1)
        XCTAssertEqual(exclusionAppsDict["com.microsoft.VSCode"], "Code")

        // Adding the same app twice is a no-op.
        settings.addExclusion(app)
        XCTAssertEqual(settings.exclusionApps.count, 1)

        settings.removeExclusion(at: 0)
        XCTAssertEqual(settings.exclusionApps.count, 0)
        XCTAssertNil(exclusionAppsDict["com.microsoft.VSCode"])
    }
}
