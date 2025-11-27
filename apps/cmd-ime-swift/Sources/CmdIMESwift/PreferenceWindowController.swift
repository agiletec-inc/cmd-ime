//
//  PreferenceWindowController.swift
//  ⌘IME
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class PreferenceWindowController: NSWindowController, NSWindowDelegate {
    static func getInstance() -> PreferenceWindowController {
        // Create window programmatically without Storyboard
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "⌘IME"
        window.center()
        window.isReleasedWhenClosed = false

        let controller = PreferenceWindowController(window: window)
        window.delegate = controller

        // Create a simple tab view with two tabs
        let tabView = NSTabView(frame: NSRect(x: 0, y: 0, width: 480, height: 320))

        // General tab
        let generalTabItem = NSTabViewItem(identifier: "general")
        generalTabItem.label = "General"
        let generalView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 300))

        let label = NSTextField(labelWithString: "⌘IME Settings")
        label.frame = NSRect(x: 20, y: 260, width: 420, height: 20)
        label.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        generalView.addSubview(label)

        let infoLabel = NSTextField(labelWithString: "Press Preferences menu to configure key mappings")
        infoLabel.frame = NSRect(x: 20, y: 220, width: 420, height: 20)
        generalView.addSubview(infoLabel)

        generalTabItem.view = generalView
        tabView.addTabViewItem(generalTabItem)

        // Shortcuts tab
        let shortcutsTabItem = NSTabViewItem(identifier: "shortcuts")
        shortcutsTabItem.label = "Shortcuts"
        let shortcutsView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 300))

        let shortcutsLabel = NSTextField(labelWithString: "Key mappings configuration")
        shortcutsLabel.frame = NSRect(x: 20, y: 260, width: 420, height: 20)
        shortcutsLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        shortcutsView.addSubview(shortcutsLabel)

        shortcutsTabItem.view = shortcutsView
        tabView.addTabViewItem(shortcutsTabItem)

        window.contentView = tabView

        return controller
    }

    func showAndActivate(_ sender: AnyObject?) {
        self.showWindow(sender)
        self.window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
    override func mouseDown(with event: NSEvent) {
        activeKeyTextField?.blur()
    }
}
