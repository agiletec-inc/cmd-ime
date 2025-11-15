import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        TabView {
            KeyMappingsView(store: store)
                .tabItem {
                    Text("キーリマップ")
                }

            ExcludedAppsView(store: store)
                .tabItem {
                    Text("除外アプリ")
                }

            GeneralSettingsView(store: store)
                .tabItem {
                    Text("設定")
                }
        }
        .padding()
    }
}

private struct KeyMappingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach(store.settings.mappings.indices, id: \.self) { index in
                    KeyMappingRow(mapping: binding(for: index))
                }
                .onDelete(perform: store.removeMappings)
            }

            HStack {
                Button {
                    store.addMapping()
                } label: {
                    Label("追加", systemImage: "plus")
                }
                Spacer()
            }
        }
    }

    private func binding(for index: Int) -> Binding<KeyMappingConfig> {
        Binding(
            get: { store.settings.mappings[index] },
            set: { store.settings.mappings[index] = $0 }
        )
    }
}

private struct KeyMappingRow: View {
    @Binding var mapping: KeyMappingConfig

    var body: some View {
        HStack {
            Toggle("", isOn: $mapping.enabled)
                .toggleStyle(.switch)
                .labelsHidden()

            Picker("Input", selection: $mapping.inputKey) {
                ForEach(InputKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 140)

            TextField("Output Source ID", text: $mapping.outputSource)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 4)
    }
}

private struct ExcludedAppsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach(store.settings.excludedApps.indices, id: \.self) { index in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { store.settings.excludedApps[index].enabled },
                            set: { store.settings.excludedApps[index].enabled = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()

                        VStack(alignment: .leading) {
                            TextField("アプリ名", text: Binding(
                                get: { store.settings.excludedApps[index].name },
                                set: { store.settings.excludedApps[index].name = $0 }
                            ))
                            TextField("Bundle ID", text: Binding(
                                get: { store.settings.excludedApps[index].bundleId },
                                set: { store.settings.excludedApps[index].bundleId = $0 }
                            ))
                            .font(.caption)
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .onDelete(perform: store.removeExcludedApps)
            }

            HStack {
                Button {
                    store.addExcludedApp()
                } label: {
                    Label("追加", systemImage: "plus")
                }
                Spacer()
            }
        }
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject private var updater = UpdateChecker.shared

    var body: some View {
        Form {
            Toggle("ログイン後にこのアプリを起動", isOn: binding(\.launchAtStartup))
            Toggle("起動時にアップデートを確認", isOn: binding(\.checkUpdatesOnStartup))

            VStack(alignment: .leading, spacing: 4) {
                Text("アップデート状態")
                    .font(.headline)
                Text(updater.state.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Button("確認する") {
                        updater.check(manual: true)
                    }
                    .disabled(updater.state == .checking)

                    if updater.state.hasUpdate {
                        Button("リリースを開く") {
                            updater.openLatestReleasePage()
                        }
                    }
                }
            }

            HStack {
                Button("設定ファイルを再読み込み") {
                    store.reloadFromDisk()
                }
                Spacer()
            }
        }
        .formStyle(.grouped)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<Settings, T>) -> Binding<T> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { store.settings[keyPath: keyPath] = $0 }
        )
    }
}
