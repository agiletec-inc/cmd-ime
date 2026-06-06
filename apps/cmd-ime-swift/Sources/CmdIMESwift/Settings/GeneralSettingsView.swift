//
//  GeneralSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtStartup)
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                Toggle("Quit ⌘IME with ⌘Q", isOn: $settings.quitOnCommandQ)
                Text("When off, ⌘Q just closes this window and ⌘IME keeps running "
                     + "in the menu bar. You can quit anytime from the menu bar icon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Check for updates on launch", isOn: $settings.checkUpdateAtLaunch)
                HStack {
                    Button("Check Now") {
                        (NSApp.delegate as? AppDelegate)?.updaterController.updater.checkForUpdates()
                    }
                    Spacer()
                    Text("Version \(version)").foregroundStyle(.secondary)
                }
            }

            Section("Input Switching") {
                Picker("Mode", selection: $settings.switchingMode) {
                    Text("Off").tag(AppSettings.SwitchingMode.global)
                    Text("Per app").tag(AppSettings.SwitchingMode.perApp)
                    Text("Smart").tag(AppSettings.SwitchingMode.smart)
                }
                .pickerStyle(.segmented)
                Group {
                    switch settings.switchingMode {
                    case .global:
                        Text("No automatic switching. Input source stays as-is when you switch apps.")
                    case .perApp:
                        Text("Remembers and restores the input source for each app when you switch.")
                    case .smart:
                        Text("Per-app memory plus auto-switch to alphanumeric in URL bars, phone, email, and ZIP fields. (Beta)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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

}
