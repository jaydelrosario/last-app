import SwiftUI
import SwiftData

@main
struct LastAppApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task { await seedFeaturesIfNeeded() }
        }
        .modelContainer(for: [
            TaskItem.self,
            TaskList.self,
            Habit.self,
            HabitLog.self,
            FeatureConfig.self,
            FeatureLink.self,
        ])
    }

    init() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
    }

    @MainActor
    private func seedFeaturesIfNeeded() async {
        guard let container = try? ModelContainer(for: FeatureConfig.self) else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<FeatureConfig>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        for (index, definition) in FeatureRegistry.all.enumerated() {
            let config = FeatureConfig(featureKey: definition.key, isEnabled: true, sortOrder: index)
            context.insert(config)
        }
        try? context.save()
    }
}
