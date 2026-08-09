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
                Toggle(L("general.launchAtLogin"), isOn: $settings.launchAtStartup)
                Toggle(L("general.showMenuBarIcon"), isOn: $settings.showMenuBarIcon)
                Toggle(L("general.quitWithCmdQ"), isOn: $settings.quitOnCommandQ)
                Text(L("general.quitWithCmdQFootnote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(L("general.checkForUpdatesOnLaunch"), isOn: $settings.checkUpdateAtLaunch)
                HStack {
                    Button(L("general.checkNow")) {
                        (NSApp.delegate as? AppDelegate)?.updaterController.updater.checkForUpdates()
                    }
                    Spacer()
                    Text(String(format: L("general.versionFormat"), version)).foregroundStyle(.secondary)
                }
            }

            Section(L("general.inputSwitchingSection")) {
                Picker(L("general.modePickerLabel"), selection: $settings.switchingMode) {
                    Text(L("general.modeOff")).tag(AppSettings.SwitchingMode.global)
                    Text(L("general.modePerApp")).tag(AppSettings.SwitchingMode.perApp)
                    Text(L("general.modeSmart")).tag(AppSettings.SwitchingMode.smart)
                }
                .pickerStyle(.segmented)
                Group {
                    switch settings.switchingMode {
                    case .global:
                        Text(L("general.modeOffDescription"))
                    case .perApp:
                        Text(L("general.modePerAppDescription"))
                    case .smart:
                        Text(L("general.modeSmartDescription"))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section(L("general.aboutSection")) {
                HStack(spacing: 8) {
                    Text("⌘IME").fontWeight(.semibold)
                    Text(String(format: L("general.versionShortFormat"), version)).foregroundStyle(.secondary)
                    Spacer()
                    Link(L("general.githubLink"), destination: URL(string: "https://github.com/agiletec-inc/cmd-ime")!)
                    Text("·").foregroundStyle(.secondary)
                    Link(L("general.issuesLink"),
                         destination: URL(string: "https://github.com/agiletec-inc/cmd-ime/issues")!)
                    Text("·").foregroundStyle(.secondary)
                    Link(L("general.licenseLink"),
                         destination: URL(string: "https://github.com/agiletec-inc/cmd-ime/blob/main/LICENSE")!)
                }
                Text(L("general.licenseFootnote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

}
