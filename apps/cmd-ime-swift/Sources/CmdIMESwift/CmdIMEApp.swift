import Cocoa
import Sparkle

var statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?
    var preferenceWindowController: PreferenceWindowController!
    let keyEvent = KeyEvent()
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Sparkle setup
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        // Load preferences and apply them to the legacy globals KeyEvent reads.
        let settings = AppSettings.shared
        settings.bootstrap()

        // Initialize preference window
        preferenceWindowController = PreferenceWindowController.getInstance()

        // Setup menu
        let menu = NSMenu()
        statusItem.button?.title = "⌘"
        statusItem.isVisible = settings.showMenuBarIcon
        statusItem.menu = menu

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        menu.addItem(
            withTitle: "⌘IME \(version) — Preferences...",
            action: #selector(AppDelegate.openPreferencesSelector(_:)),
            keyEquivalent: ","
        )
        menu.addItem(NSMenuItem.separator())
        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updateItem.target = updaterController
        menu.addItem(updateItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Restart", action: #selector(AppDelegate.restart(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "q")

        keyEvent.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        preferenceWindowController.showAndActivate(self)
        return false
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
