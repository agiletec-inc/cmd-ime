//
//  PreferenceWindowController.swift
//  ⌘IME
//
//  Hosts the SwiftUI Settings UI inside an AppKit window so the menu bar
//  agent can present and reuse it without spinning up a full Settings scene.
//

import Cocoa
import SwiftUI

final class PreferenceWindowController: NSWindowController, NSWindowDelegate {
    static func getInstance() -> PreferenceWindowController {
        let hosting = NSHostingController(
            rootView: SettingsView().environmentObject(AppSettings.shared)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "⌘IME Preferences"
        window.contentViewController = hosting
        window.center()
        window.isReleasedWhenClosed = false

        let controller = PreferenceWindowController(window: window)
        window.delegate = controller
        return controller
    }

    func showAndActivate(_ sender: AnyObject?) {
        showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
