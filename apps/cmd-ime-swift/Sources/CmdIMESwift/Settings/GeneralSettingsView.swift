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
