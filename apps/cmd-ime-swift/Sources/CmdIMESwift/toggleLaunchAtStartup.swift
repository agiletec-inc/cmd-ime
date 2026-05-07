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

@discardableResult
func setLaunchAtStartup(_ enabled: Bool) -> Bool {
    let service = SMAppService.mainApp
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
