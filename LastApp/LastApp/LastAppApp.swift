import SwiftUI
import SwiftData
import UserNotifications

@main
struct LastAppApp: App {
    @State private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([
            TaskItem.self, TaskList.self, TaskFolder.self,
            Habit.self, HabitLog.self,
            FeatureConfig.self, FeatureLink.self,
            HabitStack.self, HabitStackEntry.self,
            Exercise.self, Routine.self, RoutineEntry.self,
            WorkoutSession.self, SessionExercise.self, SessionSet.self,
            Recipe.self, Ingredient.self, RecipeStep.self, RecipeCollection.self,
            Note.self, NoteNotebook.self
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
                    seedRoutineTemplatesIfNeeded()
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                }
        }
        .modelContainer(container)
    }

    init() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
        FeatureRegistry.register(WorkoutFeature.definition)
        FeatureRegistry.register(CookingFeature.definition)
        FeatureRegistry.register(NotesFeature.definition)
    }

    @MainActor
    private func seedFeaturesIfNeeded() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<FeatureConfig>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingKeys = Set(existing.map(\.featureKey))
        let missing = FeatureRegistry.all.filter { !existingKeys.contains($0.key) }
        guard !missing.isEmpty else { return }
        let nextSortOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        for (index, definition) in missing.enumerated() {
            let config = FeatureConfig(featureKey: definition.key, isEnabled: true, sortOrder: nextSortOrder + index)
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

    @MainActor
    private func seedRoutineTemplatesIfNeeded() {
        let context = container.mainContext
        let routineDescriptor = FetchDescriptor<Routine>()
        let existingRoutines = (try? context.fetch(routineDescriptor)) ?? []
        guard existingRoutines.isEmpty else { return }

        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = (try? context.fetch(exerciseDescriptor)) ?? []
        let exerciseByName = Dictionary(exercises.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        for template in WorkoutSeedData.routineTemplates {
            let routine = Routine(name: template.name)
            context.insert(routine)
            for (i, exerciseName) in template.exercises.enumerated() {
                guard let exercise = exerciseByName[exerciseName] else { continue }
                let entry = RoutineEntry(exercise: exercise, setCount: 3, sortOrder: i)
                entry.routine = routine
                context.insert(entry)
            }
        }
        try? context.save()
    }
}
