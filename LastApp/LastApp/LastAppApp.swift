import SwiftUI
import SwiftData

@main
struct LastAppApp: App {
    @State private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([
            TaskItem.self, TaskList.self,
            Habit.self, HabitLog.self,
            FeatureConfig.self, FeatureLink.self,
            HabitStack.self, HabitStackEntry.self,
            Exercise.self, Routine.self, RoutineEntry.self,
            WorkoutSession.self, SessionExercise.self, SessionSet.self
        ])
        let container = try! ModelContainer(for: schema)
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    seedFeaturesIfNeeded()
                    seedExercisesIfNeeded()
                }
        }
        .modelContainer(container)
    }

    init() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
        FeatureRegistry.register(WorkoutFeature.definition)
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

    @MainActor
    private func seedExercisesIfNeeded() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        for exercise in WorkoutSeedData.exercises {
            context.insert(exercise)
        }
        try? context.save()
    }
}
