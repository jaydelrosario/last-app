import SwiftUI
import SwiftData

@main
struct LastAppApp: App {
    @State private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([TaskItem.self, TaskList.self, Habit.self, HabitLog.self, FeatureConfig.self, FeatureLink.self])
        let container = try! ModelContainer(for: schema)
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task { seedFeaturesIfNeeded() }
        }
        .modelContainer(container)
    }

    init() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
    }

    @MainActor
    private func seedFeaturesIfNeeded() {
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
