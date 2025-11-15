import AppKit
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: Settings {
        didSet {
            guard isInitialized else { return }
            persistChanges()
        }
    }

    private let runtime: CmdImeRuntimeClient
    private let loginItemManager: LoginItemManaging
    private let updateChecker: UpdateChecking
    private var isInitialized = false

    init(
        runtime: CmdImeRuntimeClient = SystemCmdImeRuntime(),
        loginItemManager: LoginItemManaging = LoginItemManager.shared,
        updateChecker: UpdateChecking? = nil
    ) {
        self.runtime = runtime
        self.loginItemManager = loginItemManager
        self.updateChecker = updateChecker ?? UpdateChecker.shared

        _ = runtime.initialize()
        if let loaded = SettingsStore.load(from: runtime) {
            settings = loaded
        } else {
            settings = .fallback
            persistSettingsToBackend()
        }

        loginItemManager.apply(enabled: settings.launchAtStartup)
        if settings.checkUpdatesOnStartup {
            self.updateChecker.check(manual: false)
        }
        isInitialized = true
        _ = runtime.startMonitoring()
    }

    func addMapping() {
        settings.mappings.append(
            KeyMappingConfig(
                inputKey: .commandLeft,
                outputSource: InputSource.alphanumeric.rawValue,
                enabled: true
            )
        )
    }

    func removeMappings(at offsets: IndexSet) {
        settings.mappings.remove(atOffsets: offsets)
    }

    func addExcludedApp() {
        settings.excludedApps.append(
            AppInfo(
                name: "New App",
                bundleId: "com.example.app",
                enabled: false
            )
        )
    }

    func removeExcludedApps(at offsets: IndexSet) {
        settings.excludedApps.remove(atOffsets: offsets)
    }

    func restartApp() {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [Bundle.main.bundlePath]
        try? process.run()
        NSApp.terminate(nil)
    }

    func reloadFromDisk() {
        _ = runtime.reloadSettings()
        isInitialized = false
        if let loaded = SettingsStore.load(from: runtime) {
            settings = loaded
        }
        loginItemManager.apply(enabled: settings.launchAtStartup)
        if settings.checkUpdatesOnStartup {
            updateChecker.check(manual: false)
        }
        isInitialized = true
    }

    private func persistChanges() {
        persistSettingsToBackend()
        loginItemManager.apply(enabled: settings.launchAtStartup)
        if settings.checkUpdatesOnStartup {
            updateChecker.check(manual: false)
        }
    }

    private func persistSettingsToBackend() {
        guard
            let encoded = try? SettingsStore.encoder.encode(settings),
            let json = String(data: encoded, encoding: .utf8)
        else {
            return
        }

        _ = runtime.updateSettings(json: json)
    }

    private static func load(from runtime: CmdImeRuntimeClient) -> Settings? {
        guard let json = runtime.currentSettingsJSON() else {
            return nil
        }

        return decode(json: json)
    }

    private static func decode(json: String) -> Settings? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        return try? decoder.decode(Settings.self, from: data)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }()
}
