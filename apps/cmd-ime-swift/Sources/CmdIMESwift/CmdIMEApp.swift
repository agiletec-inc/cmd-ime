import Cocoa
import Combine
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    var statusItem: NSStatusItem!
    var windowController: NSWindowController?
    var preferenceWindowController: PreferenceWindowController!
    let keyEvent = KeyEvent()
    var updaterController: SPUStandardUpdaterController!
    private var cancellables = Set<AnyCancellable>()
    private var bundleWatcher: BundleWatcher?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Load preferences before starting Sparkle so automaticallyChecksForUpdates
        // reflects the user's stored preference from the first run.
        let settings = AppSettings.shared
        settings.bootstrap()

        updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
        updaterController.updater.automaticallyChecksForUpdates = settings.checkUpdateAtLaunch
        try? updaterController.updater.start()

        settings.$checkUpdateAtLaunch
            .dropFirst()
            .sink { [weak self] value in
                self?.updaterController.updater.automaticallyChecksForUpdates = value
            }
            .store(in: &cancellables)

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

        MainActor.assumeIsolated { AutoSwitcher.shared.start() }
        keyEvent.start()

        bundleWatcher = BundleWatcher()
        bundleWatcher?.start {
            let url = URL(fileURLWithPath: Bundle.main.bundlePath)
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [url.path]
            do { try task.run() } catch {}
            NSApplication.shared.terminate(nil)
        }
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
        do { try task.run() } catch { NSLog("⌘IME: restart failed: %@", error.localizedDescription) }
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
