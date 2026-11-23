import AppKit
import SwiftUI

struct StoreMenu: View {
    @ObservedObject var model: StoreAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⌘IME").font(.headline)
            Label(model.statusMessage, systemImage: model.isListening ? "checkmark.circle" : "info.circle")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            if #available(macOS 14, *) {
                SettingsLink { Text("menu.settings") }
            } else {
                Button("menu.settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
            if model.isListening {
                Button("menu.stop") { model.stopListening() }
            } else {
                Button("menu.enable") { model.requestPermissionAndStart() }
            }
            Button("menu.quit", role: .destructive) { NSApplication.shared.terminate(nil) }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear { model.refreshPermissionState() }
    }
}
