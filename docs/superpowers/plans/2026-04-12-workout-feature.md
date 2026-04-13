# Workout Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Workout feature (Hevy-inspired) with routines, exercise library, and live session logging.

**Architecture:** Six new SwiftData models (Exercise, Routine, RoutineEntry, WorkoutSession, SessionExercise, SessionSet) wired into the existing FeatureKey/FeatureDefinition/FeatureRegistry plugin system. Navigation uses sheets for routine building and exercise picking, and a `.fullScreenCover` for the active workout session. ~40 exercises are seeded at first launch.

**Tech Stack:** SwiftUI, SwiftData, existing `FeatureDefinition`/`FeatureRegistry` system (see `LastApp/LastApp/Core/Features/`), existing `AppState` + `SidebarDestination` navigation (see `LastApp/LastApp/Core/`).

---

## File Map

**Create:**
- `LastApp/LastApp/Features/Workout/Models/MuscleGroup.swift` — enum with display name + sort order
- `LastApp/LastApp/Features/Workout/Models/Equipment.swift` — enum with display name
- `LastApp/LastApp/Features/Workout/Models/Exercise.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/Models/Routine.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/Models/RoutineEntry.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/Models/WorkoutSession.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/Models/SessionExercise.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/Models/SessionSet.swift` — SwiftData model
- `LastApp/LastApp/Features/Workout/WorkoutFeature.swift` — FeatureDefinition registration
- `LastApp/LastApp/Features/Workout/WorkoutSeedData.swift` — seed list of 40 exercises
- `LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift` — main screen
- `LastApp/LastApp/Features/Workout/Views/RoutineBuilderView.swift` — create/edit routine sheet
- `LastApp/LastApp/Features/Workout/Views/ExercisePickerView.swift` — exercise picker sheet
- `LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift` — live session full-screen cover

**Modify:**
- `LastApp/LastApp/Core/Features/FeatureKey.swift` — add `.workout`
- `LastApp/LastApp/Core/Navigation/SidebarDestination.swift` — add `.workout`
- `LastApp/LastApp/Core/Navigation/SidebarView.swift` — add `.workout` to `destinationFor()`
- `LastApp/LastApp/ContentView.swift` — add `.workout` routing in `destinationView`
- `LastApp/LastApp/LastAppApp.swift` — add models to Schema, register feature, call seed

---

## Task 1: Enums and SwiftData Models

**Files:**
- Create: `LastApp/LastApp/Features/Workout/Models/MuscleGroup.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/Equipment.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/Exercise.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/Routine.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/RoutineEntry.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/WorkoutSession.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/SessionExercise.swift`
- Create: `LastApp/LastApp/Features/Workout/Models/SessionSet.swift`

- [ ] **Step 1: Create MuscleGroup enum**

```swift
// LastApp/LastApp/Features/Workout/Models/MuscleGroup.swift
import Foundation

enum MuscleGroup: String, CaseIterable, Codable {
    case chest, back, shoulders, biceps, triceps, legs, core, cardio

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .legs: "Legs"
        case .core: "Core"
        case .cardio: "Cardio"
        }
    }

    var sortOrder: Int {
        switch self {
        case .chest: 0
        case .back: 1
        case .shoulders: 2
        case .biceps: 3
        case .triceps: 4
        case .legs: 5
        case .core: 6
        case .cardio: 7
        }
    }
}
```

- [ ] **Step 2: Create Equipment enum**

```swift
// LastApp/LastApp/Features/Workout/Models/Equipment.swift
import Foundation

enum Equipment: String, CaseIterable, Codable {
    case barbell, dumbbell, machine, bodyweight, cable, kettlebell, other

    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .bodyweight: "Bodyweight"
        case .cable: "Cable"
        case .kettlebell: "Kettlebell"
        case .other: "Other"
        }
    }
}
```

- [ ] **Step 3: Create Exercise model**

```swift
// LastApp/LastApp/Features/Workout/Models/Exercise.swift
import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupRaw: String = MuscleGroup.chest.rawValue
    var equipmentRaw: String = Equipment.barbell.rawValue
    var isCustom: Bool = false
    var createdAt: Date = Date()

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }

    init(name: String, muscleGroup: MuscleGroup, equipment: Equipment, isCustom: Bool = false) {
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.isCustom = isCustom
    }
}
```

- [ ] **Step 4: Create RoutineEntry model** (must be before Routine because Routine references it)

```swift
// LastApp/LastApp/Features/Workout/Models/RoutineEntry.swift
import SwiftData
import Foundation

@Model
final class RoutineEntry {
    var id: UUID = UUID()
    var setCount: Int = 3
    var sortOrder: Int = 0

    var routine: Routine?
    var exercise: Exercise?

    init(exercise: Exercise, setCount: Int = 3, sortOrder: Int = 0) {
        self.exercise = exercise
        self.setCount = setCount
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 5: Create Routine model**

```swift
// LastApp/LastApp/Features/Workout/Models/Routine.swift
import SwiftData
import Foundation

@Model
final class Routine {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine)
    var entries: [RoutineEntry] = []

    var orderedEntries: [RoutineEntry] {
        entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// First 3 exercise names joined by ", "
    var exerciseSummary: String {
        orderedEntries.prefix(3).compactMap { $0.exercise?.name }.joined(separator: ", ")
    }

    init(name: String) {
        self.name = name
    }
}
```

- [ ] **Step 6: Create SessionSet model** (must be before SessionExercise)

```swift
// LastApp/LastApp/Features/Workout/Models/SessionSet.swift
import SwiftData
import Foundation

@Model
final class SessionSet {
    var id: UUID = UUID()
    var setNumber: Int = 1
    var weightLbs: Double = 0
    var reps: Int = 0
    var isCompleted: Bool = false

    var sessionExercise: SessionExercise?

    init(setNumber: Int) {
        self.setNumber = setNumber
    }
}
```

- [ ] **Step 7: Create SessionExercise model** (must be before WorkoutSession)

```swift
// LastApp/LastApp/Features/Workout/Models/SessionExercise.swift
import SwiftData
import Foundation

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var sortOrder: Int = 0

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sets: [SessionSet] = []

    var orderedSets: [SessionSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    init(exercise: Exercise, sortOrder: Int = 0) {
        self.exercise = exercise
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 8: Create WorkoutSession model**

```swift
// LastApp/LastApp/Features/Workout/Models/WorkoutSession.swift
import SwiftData
import Foundation

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var finishedAt: Date? = nil
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var sessionExercises: [SessionExercise] = []

    var isActive: Bool { finishedAt == nil }

    var orderedExercises: [SessionExercise] {
        sessionExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    init() {}
}
```

- [ ] **Step 9: Commit**

```bash
git add LastApp/LastApp/Features/Workout/
git commit -m "feat: add Workout SwiftData models and enums"
```

---

## Task 2: Feature Wiring

**Files:**
- Modify: `LastApp/LastApp/Core/Features/FeatureKey.swift`
- Modify: `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`
- Create: `LastApp/LastApp/Features/Workout/WorkoutFeature.swift`
- Modify: `LastApp/LastApp/Core/Navigation/SidebarView.swift`
- Modify: `LastApp/LastApp/ContentView.swift`
- Modify: `LastApp/LastApp/LastAppApp.swift`

- [ ] **Step 1: Add `.workout` to FeatureKey**

Replace the entire file `LastApp/LastApp/Core/Features/FeatureKey.swift`:

```swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
    case workout = "workout"
}
```

- [ ] **Step 2: Add `.workout` to SidebarDestination**

Replace the entire file `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`:

```swift
// LastApp/Core/Navigation/SidebarDestination.swift
import Foundation

enum SidebarDestination: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case list(UUID)
    case habits
    case workout
    case settings
}
```

- [ ] **Step 3: Create WorkoutFeature.swift**

```swift
// LastApp/LastApp/Features/Workout/WorkoutFeature.swift
import SwiftUI

enum WorkoutFeature {
    static let definition = FeatureDefinition(
        key: .workout,
        displayName: "Workout",
        icon: "dumbbell",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Workout", systemImage: "dumbbell")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(WorkoutListView())
        }
    )
}
```

- [ ] **Step 4: Add `.workout` to SidebarView.destinationFor()**

In `LastApp/LastApp/Core/Navigation/SidebarView.swift`, find the `destinationFor` function (currently lines 122-127) and replace it:

```swift
private func destinationFor(_ key: FeatureKey) -> SidebarDestination {
    switch key {
    case .tasks: .inbox
    case .habits: .habits
    case .workout: .workout
    }
}
```

- [ ] **Step 5: Add `.workout` routing in ContentView**

In `LastApp/LastApp/ContentView.swift`, find the `destinationView` computed property and replace it:

```swift
@ViewBuilder
private var destinationView: some View {
    switch appState.selectedDestination {
    case .inbox, .upcoming, .completed, .list:
        TaskListView()
    case .today:
        TodayView()
    case .habits:
        HabitListView()
    case .workout:
        WorkoutListView()
    case .settings:
        SettingsView()
    }
}
```

- [ ] **Step 6: Update LastAppApp — Schema, registration, seed call**

Replace the entire file `LastApp/LastApp/LastAppApp.swift`:

```swift
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
```

- [ ] **Step 7: Build the app to verify no compile errors**

Open in Xcode and press ⌘B. Expected: build succeeds. The Workout sidebar item will appear but `WorkoutListView` doesn't exist yet — add a temporary placeholder if the build fails:

```swift
// Temporary — will be replaced in Task 5
struct WorkoutListView: View {
    var body: some View { Text("Workout") }
}
```

Place it at the bottom of `WorkoutFeature.swift` temporarily.

- [ ] **Step 8: Commit**

```bash
git add LastApp/LastApp/Core/Features/FeatureKey.swift
git add LastApp/LastApp/Core/Navigation/SidebarDestination.swift
git add LastApp/LastApp/Core/Navigation/SidebarView.swift
git add LastApp/LastApp/ContentView.swift
git add LastApp/LastApp/LastAppApp.swift
git add LastApp/LastApp/Features/Workout/WorkoutFeature.swift
git commit -m "feat: wire Workout feature into app navigation and schema"
```

---

## Task 3: Seed Data

**Files:**
- Create: `LastApp/LastApp/Features/Workout/WorkoutSeedData.swift`

- [ ] **Step 1: Create WorkoutSeedData.swift**

```swift
// LastApp/LastApp/Features/Workout/WorkoutSeedData.swift
import Foundation

enum WorkoutSeedData {
    static var exercises: [Exercise] {
        [
            // Chest
            Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell),
            Exercise(name: "Incline Bench Press", muscleGroup: .chest, equipment: .dumbbell),
            Exercise(name: "Push Up", muscleGroup: .chest, equipment: .bodyweight),
            Exercise(name: "Cable Fly", muscleGroup: .chest, equipment: .cable),
            Exercise(name: "Chest Dip", muscleGroup: .chest, equipment: .bodyweight),
            // Back
            Exercise(name: "Pull Up", muscleGroup: .back, equipment: .bodyweight),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipment: .machine),
            Exercise(name: "Seated Row", muscleGroup: .back, equipment: .cable),
            Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell),
            Exercise(name: "Bent Over Row", muscleGroup: .back, equipment: .barbell),
            // Shoulders
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
            Exercise(name: "Lateral Raise", muscleGroup: .shoulders, equipment: .dumbbell),
            Exercise(name: "Face Pull", muscleGroup: .shoulders, equipment: .cable),
            Exercise(name: "Arnold Press", muscleGroup: .shoulders, equipment: .dumbbell),
            // Biceps
            Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: .barbell),
            Exercise(name: "Hammer Curl", muscleGroup: .biceps, equipment: .dumbbell),
            Exercise(name: "Preacher Curl", muscleGroup: .biceps, equipment: .machine),
            Exercise(name: "Incline Curl", muscleGroup: .biceps, equipment: .dumbbell),
            // Triceps
            Exercise(name: "Triceps Pushdown", muscleGroup: .triceps, equipment: .cable),
            Exercise(name: "Skull Crusher", muscleGroup: .triceps, equipment: .barbell),
            Exercise(name: "Dip", muscleGroup: .triceps, equipment: .bodyweight),
            Exercise(name: "Overhead Extension", muscleGroup: .triceps, equipment: .dumbbell),
            // Legs
            Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell),
            Exercise(name: "Leg Press", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Romanian Deadlift", muscleGroup: .legs, equipment: .barbell),
            Exercise(name: "Leg Extension", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Leg Curl", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Calf Raise", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Lunge", muscleGroup: .legs, equipment: .dumbbell),
            // Core
            Exercise(name: "Plank", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Crunch", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Hanging Leg Raise", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .other),
            // Cardio
            Exercise(name: "Running", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Rowing", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Stair Machine", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Jump Rope", muscleGroup: .cardio, equipment: .other),
            Exercise(name: "Cycling", muscleGroup: .cardio, equipment: .machine),
        ]
    }
}
```

- [ ] **Step 2: Build and run in simulator**

Press ⌘R. Navigate to Workout in the sidebar. Verify no crash. The seed runs on first launch — confirm by checking the Xcode console for no SwiftData errors.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Workout/WorkoutSeedData.swift
git commit -m "feat: add workout exercise seed data (40 exercises)"
```

---

## Task 4: ExercisePickerView

**Files:**
- Create: `LastApp/LastApp/Features/Workout/Views/ExercisePickerView.swift`

- [ ] **Step 1: Create ExercisePickerView.swift**

```swift
// LastApp/LastApp/Features/Workout/Views/ExercisePickerView.swift
import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var selectedEquipment: Equipment? = nil
    @State private var showingMuscleFilter = false
    @State private var showingEquipmentFilter = false
    @State private var showingCreateForm = false

    // Custom exercise creation fields
    @State private var newName = ""
    @State private var newMuscle: MuscleGroup = .chest
    @State private var newEquipment: Equipment = .barbell

    private var filtered: [Exercise] {
        allExercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroup == selectedMuscle
            let matchesEquipment = selectedEquipment == nil || ex.equipment == selectedEquipment
            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }

    private var grouped: [(MuscleGroup, [Exercise])] {
        let order = MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }
        return order.compactMap { group in
            let exs = filtered.filter { $0.muscleGroup == group }
            return exs.isEmpty ? nil : (group, exs)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search exercise", text: $searchText)
                }
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Filter chips
                HStack(spacing: 10) {
                    Button {
                        showingEquipmentFilter = true
                    } label: {
                        Text(selectedEquipment?.displayName ?? "All Equipment")
                            .font(.system(.subheadline, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedEquipment != nil ? Color.appAccent.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(selectedEquipment != nil ? Color.appAccent : .primary)
                    }
                    Button {
                        showingMuscleFilter = true
                    } label: {
                        Text(selectedMuscle?.displayName ?? "All Muscles")
                            .font(.system(.subheadline, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedMuscle != nil ? Color.appAccent.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(selectedMuscle != nil ? Color.appAccent : .primary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Exercise list
                List {
                    ForEach(grouped, id: \.0) { group, exercises in
                        Section(group.displayName) {
                            ForEach(exercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.system(.body, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Text(exercise.equipment.displayName)
                                            .font(.system(.caption))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { showingCreateForm = true }
                }
            }
        }
        .sheet(isPresented: $showingEquipmentFilter) {
            equipmentFilterSheet
        }
        .sheet(isPresented: $showingMuscleFilter) {
            muscleFilterSheet
        }
        .sheet(isPresented: $showingCreateForm) {
            createExerciseSheet
        }
    }

    // MARK: - Filter Sheets

    private var equipmentFilterSheet: some View {
        NavigationStack {
            List {
                Button {
                    selectedEquipment = nil
                    showingEquipmentFilter = false
                } label: {
                    HStack {
                        Text("All Equipment").foregroundStyle(.primary)
                        Spacer()
                        if selectedEquipment == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(Equipment.allCases, id: \.self) { eq in
                    Button {
                        selectedEquipment = eq
                        showingEquipmentFilter = false
                    } label: {
                        HStack {
                            Text(eq.displayName).foregroundStyle(.primary)
                            Spacer()
                            if selectedEquipment == eq {
                                Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingEquipmentFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var muscleFilterSheet: some View {
        NavigationStack {
            List {
                Button {
                    selectedMuscle = nil
                    showingMuscleFilter = false
                } label: {
                    HStack {
                        Text("All Muscles").foregroundStyle(.primary)
                        Spacer()
                        if selectedMuscle == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { group in
                    Button {
                        selectedMuscle = group
                        showingMuscleFilter = false
                    } label: {
                        HStack {
                            Text(group.displayName).foregroundStyle(.primary)
                            Spacer()
                            if selectedMuscle == group {
                                Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingMuscleFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Create Exercise Sheet

    private var createExerciseSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $newName)
                }
                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $newMuscle) {
                        ForEach(MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Equipment") {
                    Picker("Equipment", selection: $newEquipment) {
                        ForEach(Equipment.allCases, id: \.self) { eq in
                            Text(eq.displayName).tag(eq)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newName = ""
                        showingCreateForm = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = Exercise(name: newName.trimmingCharacters(in: .whitespaces),
                                               muscleGroup: newMuscle,
                                               equipment: newEquipment,
                                               isCustom: true)
                        modelContext.insert(exercise)
                        try? modelContext.save()
                        onSelect(exercise)
                        showingCreateForm = false
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build (⌘B) — verify no compile errors**

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Workout/Views/ExercisePickerView.swift
git commit -m "feat: add ExercisePickerView with search, filters, and custom exercise creation"
```

---

## Task 5: RoutineBuilderView

**Files:**
- Create: `LastApp/LastApp/Features/Workout/Views/RoutineBuilderView.swift`

- [ ] **Step 1: Create RoutineBuilderView.swift**

```swift
// LastApp/LastApp/Features/Workout/Views/RoutineBuilderView.swift
import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pass nil to create a new routine, or an existing routine to edit it
    var existingRoutine: Routine?

    @State private var name: String = ""
    @State private var entries: [(exercise: Exercise, setCount: Int)] = []
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Routine name", text: $name)
                }

                if !entries.isEmpty {
                    Section("Exercises") {
                        ForEach(entries.indices, id: \.self) { i in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entries[i].exercise.name)
                                        .font(.system(.body, weight: .medium))
                                    Text(entries[i].exercise.muscleGroup.displayName)
                                        .font(.system(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Stepper("\(entries[i].setCount) sets",
                                        value: $entries[i].setCount,
                                        in: 1...10)
                                    .fixedSize()
                            }
                        }
                        .onDelete { indexSet in
                            entries.remove(atOffsets: indexSet)
                        }
                        .onMove { source, destination in
                            entries.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }

                Section {
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(existingRoutine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear { loadExisting() }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                entries.append((exercise: exercise, setCount: 3))
            }
        }
    }

    private func loadExisting() {
        guard let routine = existingRoutine else { return }
        name = routine.name
        entries = routine.orderedEntries.compactMap { entry in
            guard let ex = entry.exercise else { return nil }
            return (exercise: ex, setCount: entry.setCount)
        }
    }

    private func save() {
        let routine = existingRoutine ?? Routine(name: "")
        routine.name = name.trimmingCharacters(in: .whitespaces)

        // Remove old entries if editing
        for entry in routine.entries {
            modelContext.delete(entry)
        }

        // Insert new entries
        for (i, item) in entries.enumerated() {
            let entry = RoutineEntry(exercise: item.exercise, setCount: item.setCount, sortOrder: i)
            entry.routine = routine
            modelContext.insert(entry)
        }

        if existingRoutine == nil {
            modelContext.insert(routine)
        }

        try? modelContext.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Build (⌘B) — verify no compile errors**

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Workout/Views/RoutineBuilderView.swift
git commit -m "feat: add RoutineBuilderView for creating and editing routines"
```

---

## Task 6: WorkoutListView

**Files:**
- Create: `LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift`
- Modify: `LastApp/LastApp/Features/Workout/WorkoutFeature.swift` (remove temp placeholder if added)

- [ ] **Step 1: Create WorkoutListView.swift**

```swift
// LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift
import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: Routine? = nil
    @State private var activeSession: WorkoutSession? = nil
    @State private var showingActiveWorkout = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Start Empty Workout
                    Button {
                        startEmptyWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(.body, weight: .semibold))
                            Text("Start Empty Workout")
                                .font(.system(.body, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, AppTheme.padding)

                    // Routines section
                    HStack {
                        Text("Routines")
                            .font(.system(.title3, weight: .bold))
                        Spacer()
                        Button {
                            showingRoutineBuilder = true
                        } label: {
                            Image(systemName: "plus.square")
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)

                    if routines.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("No routines yet")
                                .font(.system(.subheadline))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                routineCard(routine)
                                    .padding(.horizontal, AppTheme.padding)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingRoutineBuilder) {
            RoutineBuilderView()
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineBuilderView(existingRoutine: routine)
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let session = activeSession {
                ActiveWorkoutView(session: session)
            }
        }
    }

    // MARK: - Routine Card

    private func routineCard(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.name)
                    .font(.system(.body, weight: .bold))
                Spacer()
                Menu {
                    Button { editingRoutine = routine } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(routine)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }

            if !routine.exerciseSummary.isEmpty {
                Text(routine.exerciseSummary)
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Button {
                startRoutineWorkout(routine)
            } label: {
                Text("Start Routine")
                    .font(.system(.subheadline, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Session creation

    private func startEmptyWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
        showingActiveWorkout = true
    }

    private func startRoutineWorkout(_ routine: Routine) {
        let session = WorkoutSession()
        modelContext.insert(session)

        for (i, entry) in routine.orderedEntries.enumerated() {
            guard let exercise = entry.exercise else { continue }
            let sessionExercise = SessionExercise(exercise: exercise, sortOrder: i)
            sessionExercise.session = session
            modelContext.insert(sessionExercise)

            for setNum in 1...entry.setCount {
                let set = SessionSet(setNumber: setNum)
                set.sessionExercise = sessionExercise
                modelContext.insert(set)
            }
        }

        try? modelContext.save()
        activeSession = session
        showingActiveWorkout = true
    }
}
```

- [ ] **Step 2: Remove the temporary placeholder from WorkoutFeature.swift if you added one in Task 2 Step 7**

Ensure `WorkoutFeature.swift` only contains the `WorkoutFeature` enum with `definition`.

- [ ] **Step 3: Build and run in simulator**

Press ⌘R. Navigate to Workout in the sidebar. Verify:
- "Start Empty Workout" button is visible
- "Routines" header with "+" is visible
- Empty state shows when no routines exist
- Tapping "+" opens `RoutineBuilderView`

- [ ] **Step 4: Commit**

```bash
git add LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift
git add LastApp/LastApp/Features/Workout/WorkoutFeature.swift
git commit -m "feat: add WorkoutListView with routine cards and session creation"
```

---

## Task 7: ActiveWorkoutView

**Files:**
- Create: `LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift`

- [ ] **Step 1: Create ActiveWorkoutView.swift**

```swift
// LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var elapsedSeconds: Int = 0
    @State private var showingPicker = false
    @State private var showingDiscardAlert = false
    @State private var timer: Timer? = nil

    private var hasLoggedSets: Bool {
        session.sessionExercises.contains { ex in
            ex.sets.contains { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(session.orderedExercises) { sessionExercise in
                        exerciseSection(sessionExercise)
                    }

                    // Add Exercise button
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                            .font(.system(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(timerString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasLoggedSets {
                            showingDiscardAlert = true
                        } else {
                            discardSession()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        finishWorkout()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your logged sets will be lost.")
        }
    }

    // MARK: - Exercise Section

    private func exerciseSection(_ sessionExercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sessionExercise.exercise?.name ?? "Exercise")
                .font(.system(.body, weight: .bold))
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, AppTheme.padding)

            // Column headers
            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("LBS").frame(maxWidth: .infinity, alignment: .center)
                Text("REPS").frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 44)
            }
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)

            // Set rows
            ForEach(sessionExercise.orderedSets) { set in
                setRow(set)
            }

            // Add Set
            Button {
                addSet(to: sessionExercise)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Set Row

    private func setRow(_ set: SessionSet) -> some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.system(.body, weight: .semibold))
                .frame(width: 36, alignment: .leading)

            TextField("0", value: Binding(
                get: { set.weightLbs },
                set: { set.weightLbs = $0 }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            TextField("0", value: Binding(
                get: { set.reps },
                set: { set.reps = $0 }
            ), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            // Checkmark
            Button {
                withAnimation(.spring(response: 0.25)) {
                    set.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(width: 36, height: 36)
                    if set.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.padding)
        .background(set.isCompleted ? Color.green.opacity(0.07) : Color.clear)
    }

    // MARK: - Timer

    private var timerString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(session.startedAt))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions

    private func addSet(to sessionExercise: SessionExercise) {
        let nextNumber = (sessionExercise.sets.map(\.setNumber).max() ?? 0) + 1
        let set = SessionSet(setNumber: nextNumber)
        set.sessionExercise = sessionExercise
        modelContext.insert(set)
        try? modelContext.save()
    }

    private func addExercise(_ exercise: Exercise) {
        let nextOrder = (session.sessionExercises.map(\.sortOrder).max() ?? -1) + 1
        let sessionExercise = SessionExercise(exercise: exercise, sortOrder: nextOrder)
        sessionExercise.session = session
        modelContext.insert(sessionExercise)

        let set = SessionSet(setNumber: 1)
        set.sessionExercise = sessionExercise
        modelContext.insert(set)

        try? modelContext.save()
    }

    private func finishWorkout() {
        stopTimer()
        session.finishedAt = Date()
        try? modelContext.save()
        dismiss()
    }

    private func discardSession() {
        stopTimer()
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Build and run in simulator**

Press ⌘R. Navigate to Workout → tap "Start Empty Workout". Verify:
- Full-screen cover opens
- Timer counts up in the navigation title
- "Add Exercise" button opens the exercise picker
- Adding an exercise shows it with a set row
- Tapping checkmark on a set turns it green
- "Add Set" adds another row
- "Finish" dismisses and sets `finishedAt`
- "Cancel" with no logged sets discards immediately
- "Cancel" with logged sets shows the discard alert

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift
git commit -m "feat: add ActiveWorkoutView with live timer, set logging, and finish/discard"
```
