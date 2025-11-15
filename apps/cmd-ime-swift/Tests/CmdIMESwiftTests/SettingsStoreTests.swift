import XCTest
@testable import CmdIMESwift

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testInitializationLoadsSettingsFromRuntime() {
        let initialSettings = Settings(
            launchAtStartup: true,
            checkUpdatesOnStartup: true,
            mappings: [
                KeyMappingConfig(
                    inputKey: .commandLeft,
                    outputSource: InputSource.alphanumeric.rawValue,
                    enabled: true
                )
            ],
            excludedApps: []
        )

        let runtime = MockRuntime(initialSettings: initialSettings)
        let loginManager = MockLoginItemManager()
        let updateChecker = MockUpdateChecker()

        let store = SettingsStore(
            runtime: runtime,
            loginItemManager: loginManager,
            updateChecker: updateChecker
        )

        XCTAssertEqual(store.settings.launchAtStartup, initialSettings.launchAtStartup)
        XCTAssertEqual(store.settings.checkUpdatesOnStartup, initialSettings.checkUpdatesOnStartup)
        XCTAssertEqual(store.settings.mappings.map(\.inputKey), initialSettings.mappings.map(\.inputKey))
        XCTAssertEqual(runtime.initializeCallCount, 1)
        XCTAssertEqual(runtime.startMonitoringCallCount, 1)
        XCTAssertEqual(loginManager.appliedStates, [true])
        XCTAssertEqual(updateChecker.checkCalls, [false])
    }

    func testSettingsMutationPersistsThroughRuntime() {
        var initial = Settings.fallback
        initial.launchAtStartup = true
        initial.checkUpdatesOnStartup = false

        let runtime = MockRuntime(initialSettings: initial)
        let loginManager = MockLoginItemManager()
        let updateChecker = MockUpdateChecker()

        let store = SettingsStore(
            runtime: runtime,
            loginItemManager: loginManager,
            updateChecker: updateChecker
        )

        store.settings.launchAtStartup = false
        store.settings.checkUpdatesOnStartup = true

        XCTAssertGreaterThanOrEqual(runtime.updatedPayloads.count, 2)

        if let latest = runtime.updatedPayloads.last {
            do {
                let decoded = try decodeSettings(latest)
                XCTAssertFalse(decoded.launchAtStartup)
                XCTAssertTrue(decoded.checkUpdatesOnStartup)
            } catch {
                XCTFail("Failed to decode persisted settings: \(error)\nPayload: \(latest)")
            }
        } else {
            XCTFail("No persisted settings were captured")
        }

        XCTAssertEqual(loginManager.appliedStates.last, false)
        XCTAssertEqual(updateChecker.checkCalls.last, false)
    }
}

private final class MockRuntime: CmdImeRuntimeClient {
    private(set) var initializeCallCount = 0
    private(set) var startMonitoringCallCount = 0
    private(set) var reloadCallCount = 0
    private var storedJSON: String?

    var updatedPayloads: [String] = []

    init(initialSettings: Settings?) {
        if let initialSettings, let json = encodeSettings(initialSettings) {
            storedJSON = json
        }
    }

    @discardableResult
    func initialize() -> Bool {
        initializeCallCount += 1
        return true
    }

    @discardableResult
    func startMonitoring() -> Bool {
        startMonitoringCallCount += 1
        return true
    }

    func stopMonitoring() {}

    @discardableResult
    func reloadSettings() -> Bool {
        reloadCallCount += 1
        return true
    }

    func currentSettingsJSON() -> String? {
        storedJSON
    }

    @discardableResult
    func updateSettings(json: String) -> Bool {
        updatedPayloads.append(json)
        storedJSON = json
        return true
    }
}

private final class MockLoginItemManager: LoginItemManaging {
    private(set) var appliedStates: [Bool] = []

    func apply(enabled: Bool) {
        appliedStates.append(enabled)
    }

    func isEnabled() -> Bool {
        appliedStates.last ?? false
    }
}

private final class MockUpdateChecker: UpdateChecking {
    private(set) var checkCalls: [Bool] = []

    func check(manual: Bool) {
        checkCalls.append(manual)
    }
}

private func encodeSettings(_ settings: Settings) -> String? {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted]
    guard let data = try? encoder.encode(settings) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}

private func decodeSettings(_ json: String) throws -> Settings {
    guard let data = json.data(using: .utf8) else {
        throw NSError(domain: "SettingsStoreTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
    }
    let decoder = JSONDecoder()
    return try decoder.decode(Settings.self, from: data)
}
