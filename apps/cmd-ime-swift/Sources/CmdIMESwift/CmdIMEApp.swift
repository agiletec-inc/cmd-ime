import SwiftUI

@main
struct CmdIMEApp: App {
    @StateObject private var store = SettingsStore()

    var body: some Scene {
        MenuBarExtra("⌘IME", systemImage: "command") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.window)

        Window("⌘IME Preferences", id: "com.kazuki.cmdime.preferences") {
            PreferencesView(store: store)
                .frame(minWidth: 520, minHeight: 360)
        }
    }
}
