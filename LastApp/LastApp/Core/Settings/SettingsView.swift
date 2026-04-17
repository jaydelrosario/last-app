// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]
    @AppStorage("restTimerDuration") private var restTimerDuration: Int = 60
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday: Bool = false
    @AppStorage("showInbox") private var showInbox: Bool = true
    @AppStorage("showToday") private var showToday: Bool = true
    @AppStorage("showUpcoming") private var showUpcoming: Bool = true
    @AppStorage("showCompleted") private var showCompleted: Bool = true

    @State private var showingFilePicker = false
    @State private var importState: ImportState = .idle

    private let restTimerOptions = [30, 60, 90, 120, 180, 300]

    var body: some View {
        List {
            Section("Tasks") {
                Toggle("Show Inbox", isOn: $showInbox)
                Toggle("Show Today", isOn: $showToday)
                Toggle("Show Upcoming", isOn: $showUpcoming)
                Toggle("Show Completed", isOn: $showCompleted)
            }

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

            Section("Data") {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Label("Import from TickTick", systemImage: "arrow.down.doc")
                            .foregroundStyle(.primary)
                        Spacer()
                        if case .importing = importState {
                            ProgressView()
                        }
                    }
                }
                .disabled({
                    if case .importing = importState { return true }
                    return false
                }())

                switch importState {
                case .success(let result):
                    Text("\(result.foldersCreated) folders · \(result.listsCreated) lists · \(result.tasksCreated) tasks imported, \(result.skipped) skipped")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .failure(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                default:
                    EmptyView()
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText]
            ) { result in
                switch result {
                case .success(let url):
                    let accessed = url.startAccessingSecurityScopedResource()
                    importState = .importing
                    Task {
                        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let importResult = try await TickTickImporter().run(url: url, context: modelContext)
                            importState = .success(importResult)
                        } catch {
                            importState = .failure(error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    importState = .failure(error.localizedDescription)
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

    private enum ImportState {
        case idle
        case importing
        case success(ImportResult)
        case failure(String)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [FeatureConfig.self], inMemory: true)
}
