import Foundation

protocol LoginItemManaging {
    func apply(enabled: Bool)
    func isEnabled() -> Bool
}

/// Simple LaunchAgent-based login item controller.
final class LoginItemManager {
    static let shared = LoginItemManager()

    private let label = "com.kazuki.cmdime.launcher"
    private let fileManager = FileManager.default

    private var agentURL: URL {
        fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    func apply(enabled: Bool) {
        if enabled {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }

    func isEnabled() -> Bool {
        fileManager.fileExists(atPath: agentURL.path)
    }

    @discardableResult
    private func installLaunchAgent() -> Bool {
        guard let executable = Bundle.main.executableURL else {
            return false
        }

        let payload: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executable.path],
            "RunAtLoad": true,
            "KeepAlive": false,
        ]

        do {
            try fileManager.createDirectory(
                at: agentURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try PropertyListSerialization.data(
                fromPropertyList: payload,
                format: .xml,
                options: 0
            )
            try data.write(to: agentURL, options: .atomic)
            return true
        } catch {
            NSLog("Failed to install LaunchAgent: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    private func removeLaunchAgent() -> Bool {
        guard fileManager.fileExists(atPath: agentURL.path) else {
            return true
        }

        do {
            try fileManager.removeItem(at: agentURL)
            return true
        } catch {
            NSLog("Failed to remove LaunchAgent: \(error.localizedDescription)")
            return false
        }
    }
}

extension LoginItemManager: LoginItemManaging {}
