import CmdIMEStoreCore
import SwiftUI

struct StoreSettingsView: View {
    @ObservedObject var model: StoreAppModel

    var body: some View {
        Form {
            Section("settings.shortcuts") {
                sourcePicker(title: String(localized: "settings.leftCommand"), selection: $model.leftSourceID)
                sourcePicker(title: String(localized: "settings.rightCommand"), selection: $model.rightSourceID)
                if !model.leftSourceID.isEmpty && !model.inputSources.contains(where: { $0.id == model.leftSourceID }) {
                    Text("settings.unavailableAssignment")
                        .foregroundStyle(.secondary)
                }
                if !model.rightSourceID.isEmpty && !model.inputSources.contains(where: { $0.id == model.rightSourceID }) {
                    Text("settings.unavailableAssignment")
                        .foregroundStyle(.secondary)
                }
                Text("settings.sourceHint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.permission") {
                Text(model.listenPermissionGranted
                     ? String(localized: "settings.permissionGranted")
                     : String(localized: "settings.permissionRequired"))
                if model.isListening {
                    Button("settings.stop") { model.stopListening() }
                } else {
                    Button("settings.enable") { model.requestPermissionAndStart() }
                }
                if !model.listenPermissionGranted {
                    Button("settings.openPrivacy") { model.openInputMonitoringSettings() }
                }
                Text("settings.permissionHint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("settings.imeCaveat")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Link("settings.privacyPolicy", destination: URL(string: "https://github.com/agiletec-inc/cmd-ime/blob/main/docs/app-store/privacy.md")!)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 480, height: 480)
        .navigationTitle("⌘IME")
        .onAppear { model.refreshInputSources() }
        .onChange(of: model.leftSourceID) { _ in model.refreshInputSources() }
        .onChange(of: model.rightSourceID) { _ in model.refreshInputSources() }
    }

    private func sourcePicker(title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            Text("settings.noAssignment").tag("")
            if !selection.wrappedValue.isEmpty && !model.inputSources.contains(where: { $0.id == selection.wrappedValue }) {
                Text("settings.unavailableInputSource").tag(selection.wrappedValue)
            }
            ForEach(model.inputSources) { source in
                Text(source.localizedName).tag(source.id)
            }
        }
    }
}
