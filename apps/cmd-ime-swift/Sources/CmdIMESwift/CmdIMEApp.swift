import Cocoa

var statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?
    var preferenceWindowController: PreferenceWindowController!
    let keyEvent = KeyEvent()
    private let bundleWatcher = BundleWatcher()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
        menu.addItem(withTitle: "Restart", action: #selector(AppDelegate.restart(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "q")

        keyEvent.start()

        if settings.checkUpdateAtLaunch {
            checkUpdate()
        }

        // brew upgrade mv-replaces /Applications/CmdIME.app while we're running.
        // macOS leaves us alive on the old Mach-O image with a cached Info.plist,
        // which makes "Check Now" report a stale version. Restart on replace.
        bundleWatcher.start { [weak self] in
            guard let self else { return }
            self.restart(self)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        bundleWatcher.stop()
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
