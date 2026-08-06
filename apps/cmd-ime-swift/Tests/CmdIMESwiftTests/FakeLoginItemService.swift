import ServiceManagement
@testable import CmdIMESwift

/// In-memory stand-in for `SMAppService.mainApp` (see LoginItemService in
/// toggleLaunchAtStartup.swift). Tests must never touch the real OS-level
/// login item registry: a prior bug had a test call the real API, which
/// registered the `xctest` test-runner binary itself as a login item on the
/// developer's Mac (see CLAUDE.md and AppSettingsTests.swift for the
/// incident this class exists to prevent).
final class FakeLoginItemService: LoginItemService {
    var status: SMAppService.Status
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    var registerError: Error?
    var unregisterError: Error?

    init(status: SMAppService.Status = .notRegistered) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        if let registerError { throw registerError }
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError { throw unregisterError }
        status = .notRegistered
    }
}
