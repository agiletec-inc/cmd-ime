import SwiftUI

@main
struct CmdIMEStoreApp: App {
    @StateObject private var model = StoreAppModel()

    var body: some Scene {
        MenuBarExtra("⌘IME", systemImage: "keyboard") {
            StoreMenu(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            StoreSettingsView(model: model)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
