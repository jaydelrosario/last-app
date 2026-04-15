// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]
    @AppStorage("restTimerDuration") private var restTimerDuration: Int = 60
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday: Bool = false

    private let restTimerOptions = [30, 60, 90, 120, 180, 300]

    var body: some View {
        List {
            Section("Habits") {
                Picker("Week Starts On", selection: $weekStartsOnMonday) {
                    Text("Sunday").tag(false)
                    Text("Monday").tag(true)
                }
            }

            Section("Workout") {
                Picker("Rest Timer", selection: $restTimerDuration) {
                    ForEach(restTimerOptions, id: \.self) { seconds in
                        Text(restTimerLabel(seconds)).tag(seconds)
                    }
                }
                Picker("Weight Unit", selection: $weightUnit) {
                    Text("lbs").tag("lbs")
                    Text("kg").tag("kg")
                }
            }

            Section("Features") {
                ForEach(featureConfigs) { config in
                    if let definition = FeatureRegistry.definition(for: config.featureKey) {
                        FeatureToggleView(
                            definition: definition,
                            isEnabled: Binding(
                                get: { config.isEnabled },
                                set: { config.isEnabled = $0 }
                            )
                        )
                    }
                }
                .onMove { source, destination in
                    var reordered = featureConfigs
                    reordered.move(fromOffsets: source, toOffset: destination)
                    for (index, config) in reordered.enumerated() {
                        config.sortOrder = index
                    }
                    try? modelContext.save()
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
        .toolbar {
            EditButton()
        }
    }

    private func restTimerLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return secs == 0 ? "\(mins) min" : "\(mins)m \(secs)s"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [FeatureConfig.self], inMemory: true)
}
