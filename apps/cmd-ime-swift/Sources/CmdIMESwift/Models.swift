import Foundation

struct Settings: Codable, Equatable {
    var launchAtStartup: Bool
    var checkUpdatesOnStartup: Bool
    var mappings: [KeyMappingConfig]
    var excludedApps: [AppInfo]

    static let fallback = Settings(
        launchAtStartup: true,
        checkUpdatesOnStartup: true,
        mappings: [
            KeyMappingConfig(
                inputKey: .commandLeft,
                outputSource: InputSource.alphanumeric.rawValue,
                enabled: true
            ),
            KeyMappingConfig(
                inputKey: .commandRight,
                outputSource: InputSource.hiragana.rawValue,
                enabled: true
            ),
        ],
        excludedApps: []
    )

    enum CodingKeys: String, CodingKey {
        case launchAtStartup = "launch_at_startup"
        case checkUpdatesOnStartup = "check_updates_on_startup"
        case mappings
        case excludedApps = "excluded_apps"
    }
}

struct KeyMappingConfig: Identifiable, Codable, Equatable {
    var inputKey: InputKey
    var outputSource: String
    var enabled: Bool
    private let identifier = UUID()

    var id: UUID { identifier }

    enum CodingKeys: String, CodingKey {
        case inputKey = "input_key"
        case outputSource = "output_source"
        case enabled
    }

    init(inputKey: InputKey, outputSource: String, enabled: Bool) {
        self.inputKey = inputKey
        self.outputSource = outputSource
        self.enabled = enabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inputKey = try container.decode(InputKey.self, forKey: .inputKey)
        outputSource = try container.decode(String.self, forKey: .outputSource)
        enabled = try container.decode(Bool.self, forKey: .enabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inputKey, forKey: .inputKey)
        try container.encode(outputSource, forKey: .outputSource)
        try container.encode(enabled, forKey: .enabled)
    }
}

struct AppInfo: Identifiable, Codable, Equatable {
    var name: String
    var bundleId: String
    var enabled: Bool

    var id: String { bundleId }

    enum CodingKeys: String, CodingKey {
        case name
        case bundleId = "bundle_id"
        case enabled
    }
}

enum InputKey: String, CaseIterable, Identifiable, Codable {
    case commandLeft = "Command_L"
    case commandRight = "Command_R"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .commandLeft:
            return "Command_L"
        case .commandRight:
            return "Command_R"
        }
    }
}

enum InputSource: String, CaseIterable, Identifiable {
    case alphanumeric = "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman"
    case hiragana = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alphanumeric:
            return "英数"
        case .hiragana:
            return "かな"
        }
    }
}
