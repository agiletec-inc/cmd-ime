import XCTest
@testable import CmdIMESwift

@MainActor
final class MenuFlowUITests: XCTestCase {
    func testMenuBarViewBindingsToggleWithoutSideEffects() {
        let runtime = MockRuntime()
        let loginManager = MockLoginItemManager()
        let updateChecker = MockUpdateChecker()
        let store = SettingsStore(
            runtime: runtime,
            loginItemManager: loginManager,
            updateChecker: updateChecker
        )

        // Simulate toggling the login item switch in the menu bar UI.
        store.settings.launchAtStartup = false
        XCTAssertEqual(loginManager.appliedStates.last, false)

        // Simulate adding/removing mappings via the preferences UI.
        store.addMapping()
        store.removeMappings(at: IndexSet(integer: store.settings.mappings.count - 1))
        XCTAssertGreaterThanOrEqual(store.settings.mappings.count, 2)
    }
}

private final class MockRuntime: CmdImeRuntimeClient {
    @discardableResult func initialize() -> Bool { true }
    @discardableResult func startMonitoring() -> Bool { true }
    func stopMonitoring() {}
    @discardableResult func reloadSettings() -> Bool { true }
    func currentSettingsJSON() -> String? { Settings.fallbackJSON }
    @discardableResult func updateSettings(json: String) -> Bool { true }
}

private final class MockLoginItemManager: LoginItemManaging {
    private(set) var appliedStates: [Bool] = []
    func apply(enabled: Bool) { appliedStates.append(enabled) }
    func isEnabled() -> Bool { appliedStates.last ?? false }
}

@MainActor
private final class MockUpdateChecker: UpdateChecking {
    func check(manual: Bool) {}
}

private extension Settings {
    static var fallbackJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try! encoder.encode(Settings.fallback)
        return String(data: data, encoding: .utf8)!
    }
}
