import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("ログイン時に開く", isOn: binding(\.launchAtStartup))
            Divider()
            Button("About ⌘IME") {
                NSApp.orderFrontStandardAboutPanel(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Preferences…") {
                openWindow(id: preferencesWindowID)
            }
            Button("Restart") {
                store.restartApp()
            }
            Button("Quit") {
                CmdImeRuntime.stopMonitoring()
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(minWidth: 220)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<Settings, T>) -> Binding<T> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { store.settings[keyPath: keyPath] = $0 }
        )
    }

    private var preferencesWindowID: String { "com.kazuki.cmdime.preferences" }
}
