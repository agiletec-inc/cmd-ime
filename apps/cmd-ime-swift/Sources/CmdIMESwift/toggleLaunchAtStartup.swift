//
//  toggleLaunchAtStartup.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

// ログイン項目に追加、またはそこから削除するための関数

import Cocoa
import ServiceManagement

func setLaunchAtStartup(_ enabled: Bool) {
    if #available(macOS 13.0, *) {
        // macOS 13+ uses SMAppService
        do {
            let service = SMAppService.mainApp
            if enabled {
                if service.status == .enabled {
                    print("Login item already enabled.")
                } else {
                    try service.register()
                    print("Successfully registered login item.")
                }
            } else {
                if service.status == .notRegistered {
                    print("Login item already disabled.")
                } else {
                    try service.unregister()
                    print("Successfully unregistered login item.")
                }
            }
        } catch {
            print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    } else {
        // Legacy method for macOS 12 and earlier
        let appBundleIdentifier = "com.kazuki.cmdime-helper"

        if SMLoginItemSetEnabled(appBundleIdentifier as CFString, enabled) {
            if enabled {
                print("Successfully add login item.")
            } else {
                print("Successfully remove login item.")
            }
        } else {
            print("Failed to add login item.")
        }
    }
}
