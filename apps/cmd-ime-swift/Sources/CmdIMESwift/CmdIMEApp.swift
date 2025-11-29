import Cocoa

var statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?
    var preferenceWindowController: PreferenceWindowController!
    let keyEvent = KeyEvent()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let userDefaults = UserDefaults.standard

        // Load exclusion apps
        if let exclusionAppsListData = userDefaults.object(forKey: "exclusionApps") as? [[AnyHashable: Any]] {
            for val in exclusionAppsListData {
                if let exclusionApps = AppData(dictionary: val) {
                    exclusionAppsList.append(exclusionApps)
                }
            }

            for val in exclusionAppsList {
                exclusionAppsDict[val.id] = val.name
            }
        }

        // Load key mappings
        if let keyMappingListData = userDefaults.object(forKey: "mappings") as? [[AnyHashable: Any]] {
            for val in keyMappingListData {
                if let mapping = KeyMapping(dictionary: val) {
                    keyMappingList.append(mapping)
                }
            }

            keyMappingListToShortcutList()
        } else {
            // Default settings
            keyMappingList = [
                KeyMapping(input: KeyboardShortcut(keyCode: 55), output: KeyboardShortcut(keyCode: 102)),
                KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
            ]

            saveKeyMappings()
            keyMappingListToShortcutList()
        }

        // Initialize preference window
        preferenceWindowController = PreferenceWindowController.getInstance()

        // Setup menu
        let menu = NSMenu()
        statusItem.button?.title = "⌘"
        statusItem.menu = menu

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        menu.addItem(
            withTitle: "About ⌘IME \(version)",
            action: #selector(AppDelegate.open(_:)),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: "Preferences...",
            action: #selector(AppDelegate.openPreferencesSelector(_:)),
            keyEquivalent: ""
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Restart", action: #selector(AppDelegate.restart(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")

        keyEvent.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationDidResignActive(_ notification: Notification) {
        activeKeyTextField?.blur()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        preferenceWindowController.showAndActivate(self)
        return false
    }

    @IBAction func open(_ sender: AnyObject) {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func openPreferencesSelector(_ sender: AnyObject) {
        preferenceWindowController.showAndActivate(self)
    }

    @IBAction func restart(_ sender: AnyObject) {
        let url = URL(fileURLWithPath: Bundle.main.bundlePath)
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [url.path]
        task.launch()
        NSApplication.shared.terminate(self)
    }

    @IBAction func quit(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
}

@main
class Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
