//
//  toggleLaunchAtStartup.swift
//  ⌘IME
//
//  Registers / unregisters the app as a Login Item via the modern
//  ServiceManagement API. The legacy SMLoginItemSetEnabled-with-helper
//  bundle path was removed because Package.swift requires macOS 13.0+.
//

import Cocoa
import ServiceManagement

/// Seam over `SMAppService.mainApp` so tests can inject a fake instead of
/// hitting the real OS-level login item registry. `SMAppService` already has
/// matching `status`/`register()`/`unregister()` members, so it conforms for
/// free — see the extension below.
protocol LoginItemService {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemService {}

@discardableResult
func setLaunchAtStartup(_ enabled: Bool, service: LoginItemService = SMAppService.mainApp) -> Bool {
    do {
        if enabled {
            guard service.status != .enabled else { return true }
            try service.register()
        } else {
            guard service.status != .notRegistered else { return true }
            try service.unregister()
        }
        return true
    } catch {
        NSLog("⌘IME: failed to %@ login item: %@",
              enabled ? "register" : "unregister",
              error.localizedDescription)
        return false
    }
}
