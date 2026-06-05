import Cocoa
import Combine
import Sparkle
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate,
                   SPUStandardUserDriverDelegate, UNUserNotificationCenterDelegate {
    static weak var shared: AppDelegate?

    // Identifier for the "update available" banner posted on background checks.
    private static let updateNotificationIdentifier = "UpdateCheck"

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

        startSparkleUpdater(settings: settings)

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
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [url.path]
            do { try task.run() } catch {}
            NSApplication.shared.terminate(nil)
        }
    }

    /// Configures and starts Sparkle, wiring the gentle-reminder delegates for this
    /// menu bar agent and keeping automatic checks in sync with the user's preference.
    private func startSparkleUpdater(settings: AppSettings) {
        // userDriverDelegate enables Sparkle's "gentle reminders" for this LSUIElement
        // menu bar agent: on a background/scheduled check we bring the app forward and
        // post a Notification Center banner, instead of silently popping a dialog the
        // user (who has no Dock icon to glance at) may never notice.
        UNUserNotificationCenter.current().delegate = self
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        updaterController.updater.automaticallyChecksForUpdates = settings.checkUpdateAtLaunch
        do {
            try updaterController.updater.start()
        } catch {
            NSLog("⌘IME: Sparkle updater failed to start: %@", error.localizedDescription)
        }

        settings.$checkUpdateAtLaunch
            .dropFirst()
            .sink { [weak self] value in
                self?.updaterController.updater.automaticallyChecksForUpdates = value
            }
            .store(in: &cancellables)
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
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [url.path]
        do { try task.run() } catch { NSLog("⌘IME: restart failed: %@", error.localizedDescription) }
        NSApplication.shared.terminate(self)
    }

    @IBAction func quit(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }

    // MARK: - Gentle update reminders (SPUStandardUserDriverDelegate)
    //
    // ⌘IME runs as an LSUIElement menu bar agent with no Dock icon, so Sparkle's
    // standard update alert can surface behind other windows on an automatic check.
    // Following Sparkle's "gentle reminders" guidance for background apps, we bring
    // the app to the foreground while an update is on screen and post a Notification
    // Center banner for non-user-initiated checks.
    // https://sparkle-project.org/documentation/gentle-reminders

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // Bring the agent forward so the update dialog is frontmost and focusable.
        NSApp.setActivationPolicy(.regular)

        // Only nudge via a banner when the check was scheduled in the background; a
        // user-initiated "Check for Updates…" already has the user's attention.
        guard !state.userInitiated else { return }

        NSApp.dockTile.badgeLabel = "1"
        let content = UNMutableNotificationContent()
        content.title = "⌘IME の新しいバージョンがあります"
        content.body = "v\(update.displayVersionString) をインストールできます"
        let request = UNNotificationRequest(
            identifier: Self.updateNotificationIdentifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        // The user engaged with the update, so clear the badge and any stale banner.
        NSApp.dockTile.badgeLabel = ""
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [Self.updateNotificationIdentifier])
    }

    func standardUserDriverWillFinishUpdateSession() {
        // Return to menu-bar-only presence once the update interaction is over.
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - SPUUpdaterDelegate

    func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        // Ask for notification permission only once automatic checks are actually
        // scheduled (i.e. the user kept "check for updates on launch" enabled).
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(.banner)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == Self.updateNotificationIdentifier,
           response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // Clicking the banner opens Sparkle's update dialog.
            updaterController.updater.checkForUpdates()
        }
        completionHandler()
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
