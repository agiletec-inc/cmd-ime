//
//  GeneralSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var isCheckingForUpdates = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtStartup)
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
            }

            Section {
                Toggle("Check for updates on launch", isOn: $settings.checkUpdateAtLaunch)
                HStack {
                    Button {
                        runManualUpdateCheck()
                    } label: {
                        if isCheckingForUpdates {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Check Now")
                        }
                    }
                    .disabled(isCheckingForUpdates)
                    Spacer()
                    Text("Version \(version)").foregroundStyle(.secondary)
                }
            }

            Section("About") {
                HStack(spacing: 8) {
                    Text("⌘IME").fontWeight(.semibold)
                    Text("v\(version)").foregroundStyle(.secondary)
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/agiletec-inc/cmd-ime")!)
                    Text("·").foregroundStyle(.secondary)
                    Link("Issues", destination: URL(string: "https://github.com/agiletec-inc/cmd-ime/issues")!)
                    Text("·").foregroundStyle(.secondary)
                    Link("License", destination: URL(string: "https://github.com/agiletec-inc/cmd-ime/blob/main/LICENSE")!)
                }
                Text("MIT License · Based on the original cmd-eikana by iMasanari")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func runManualUpdateCheck() {
        isCheckingForUpdates = true
        checkUpdate(manual: true) { _ in
            isCheckingForUpdates = false
        }
    }
}
