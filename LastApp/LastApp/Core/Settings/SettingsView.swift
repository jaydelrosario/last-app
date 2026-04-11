// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]

    var body: some View {
        List {
            Section("Features") {
                ForEach(FeatureRegistry.all, id: \.key) { definition in
                    if let config = featureConfigs.first(where: { $0.featureKey == definition.key }) {
                        FeatureToggleView(
                            definition: definition,
                            isEnabled: Binding(
                                get: { config.isEnabled },
                                set: { config.isEnabled = $0 }
                            )
                        )
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [FeatureConfig.self], inMemory: true)
}
