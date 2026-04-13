# Workout Feature Design

## Goal

Add a Workout feature to LastApp, inspired by the Hevy app, allowing users to log gym sessions either from scratch or via saved routines.

## Architecture

Follows the existing feature plugin pattern (`FeatureKey` → `FeatureDefinition` → `FeatureRegistry`). Six new SwiftData models. Navigation uses sheets for creation flows and a `.fullScreenCover` for the active workout session. Seeded with ~40 common exercises at first launch.

## Tech Stack

SwiftUI, SwiftData, existing `FeatureDefinition`/`FeatureRegistry` system.

---

## Data Models

### `Exercise`
- `id: UUID`
- `name: String`
- `muscleGroup: MuscleGroup` (enum: chest, back, shoulders, biceps, triceps, legs, core, cardio)
- `equipment: Equipment` (enum: barbell, dumbbell, machine, bodyweight, cable, kettlebell, other)
- `isCustom: Bool` — false for seeded exercises, true for user-created
- `createdAt: Date`

### `Routine`
- `id: UUID`
- `name: String`
- `createdAt: Date`
- `entries: [RoutineEntry]` (cascade delete)

### `RoutineEntry`
- `id: UUID`
- `exercise: Exercise`
- `setCount: Int`
- `sortOrder: Int`

### `WorkoutSession`
- `id: UUID`
- `startedAt: Date`
- `finishedAt: Date?` — nil means session is currently active
- `notes: String`
- `sessionExercises: [SessionExercise]` (cascade delete)

### `SessionExercise`
- `id: UUID`
- `exercise: Exercise`
- `sortOrder: Int`
- `sets: [SessionSet]` (cascade delete)

### `SessionSet`
- `id: UUID`
- `setNumber: Int`
- `weightLbs: Double`
- `reps: Int`
- `isCompleted: Bool`

---

## Feature Wiring

- Add `.workout` to `FeatureKey` enum
- Add `.workout` to `SidebarDestination` enum
- Add `WorkoutFeature.swift` — `FeatureDefinition` with key `.workout`, displayName `"Workout"`, icon `"dumbbell"`
- Register `WorkoutFeature.definition` in `LastAppApp.init()`
- Add all 6 new models to `Schema` in `LastAppApp`
- Add `seedExercisesIfNeeded()` called from `.task {}` alongside `seedFeaturesIfNeeded()`
- Add `.workout` case to `SidebarView.destinationFor()`
- Route `.workout` → `WorkoutListView` in `ContentView`

---

## Views

### `WorkoutListView` (root)
- `Color(uiColor: .systemGroupedBackground)` background
- "Start Empty Workout" full-width button at top (accent color, rounded)
- "Routines" section header with "+" button to create a routine
- Each routine: card with name, exercise summary (first 3 exercise names joined by ", "), "Start Routine" blue button
- Routine card context menu: Edit, Delete
- Empty state when no routines exist
- Sheet: `RoutineBuilderView` for create/edit
- `.fullScreenCover`: `ActiveWorkoutView` when session is active

### `RoutineBuilderView` (sheet)
- Navigation bar: "Cancel" (left), title "New Routine" or "Edit Routine", "Save" (right, disabled until name non-empty)
- Text field for routine name
- List of added exercises: name + set count stepper (1–10)
- Swipe-to-delete exercises
- Drag-to-reorder exercises (`.onMove`)
- "Add Exercise" button → presents `ExercisePickerView` as sheet

### `ExercisePickerView` (sheet)
- Navigation bar: "Cancel" (left), title "Add Exercise", "Create" (right) → inline form for custom exercise
- Search bar (filters by name)
- Two filter chips: "All Equipment" and "All Muscles" — each opens a picker sheet
- Exercise list: grouped by muscle group, each row shows name + equipment subtitle
- Tap row to select and dismiss (returns exercise to caller via binding or callback)

### `ActiveWorkoutView` (`.fullScreenCover`)
- Navigation bar: elapsed timer (MM:SS, counts up) in center, "Finish Workout" button on right
- Each exercise section: name header + rows of (set number | weight text field | reps text field | checkmark button)
- Checkmark button marks set as completed (fills green)
- "Add Set" button below each exercise's sets
- "Add Exercise" button at bottom of scroll view → presents `ExercisePickerView`
- "Finish Workout" sets `finishedAt = Date()` and dismisses cover
- Discard option: "Cancel" with confirmation alert if any sets have been logged

---

## Seed Data (~40 exercises, `isCustom: false`)

| Muscle Group | Exercises |
|---|---|
| Chest | Bench Press (Barbell), Incline Bench Press (Dumbbell), Push Up (Bodyweight), Cable Fly (Cable), Chest Dip (Bodyweight) |
| Back | Pull Up (Bodyweight), Lat Pulldown (Machine), Seated Row (Cable), Deadlift (Barbell), Bent Over Row (Barbell) |
| Shoulders | Overhead Press (Barbell), Lateral Raise (Dumbbell), Face Pull (Cable), Arnold Press (Dumbbell) |
| Biceps | Barbell Curl (Barbell), Hammer Curl (Dumbbell), Preacher Curl (Machine), Incline Curl (Dumbbell) |
| Triceps | Triceps Pushdown (Cable), Skull Crusher (Barbell), Dip (Bodyweight), Overhead Extension (Dumbbell) |
| Legs | Squat (Barbell), Leg Press (Machine), Romanian Deadlift (Barbell), Leg Extension (Machine), Leg Curl (Machine), Calf Raise (Machine), Lunge (Dumbbell) |
| Core | Plank (Bodyweight), Crunch (Bodyweight), Hanging Leg Raise (Bodyweight), Ab Wheel Rollout (Other) |
| Cardio | Running (Machine), Rowing (Machine), Stair Machine (Machine), Jump Rope (Other), Cycling (Machine) |

Seeding runs once (guard: fetch `Exercise` count > 0 → skip).
