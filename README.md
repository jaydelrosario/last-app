# LastApp

An all-in-one iOS productivity app that replaces multiple single-purpose apps. Built with SwiftUI and SwiftData, targeting iOS 17+.

## What This Is

LastApp is a native iOS app with a modular feature system. The core is a TickTick-inspired task manager. Additional features (habits, workouts, and more planned) plug into the same app via a feature registry — each can be toggled on/off from Settings, and enabled features appear in the sidebar.

The goal: one daily-driver app instead of a dozen.

## Tech Stack

| Layer | Choice |
|---|---|
| Platform | iOS 17+ (native) |
| UI | SwiftUI |
| Persistence | SwiftData (local SQLite, offline-first) |
| Architecture | MVVM with `@Observable` (Swift Observation, not Combine) |
| State | `AppState` (`@Observable`) injected via `.environment()` + SwiftData `@Query` |
| Navigation | Custom sidebar drawer (ZStack overlay, edge-swipe gestures) + `NavigationStack` |
| Project | Xcode project (`LastApp.xcodeproj`) — no SPM workspace |

## Current Status

**Implemented features:**

- **Tasks** — full CRUD, inbox/today/upcoming/completed smart lists, custom lists, priority (P1–P4), subtasks, tags, drag-to-reorder, quick-add FAB, detail view
- **Habits** — daily/weekly habits, streak tracking (computed from logs), habit stacks (Atomic Habits chaining), 30-day calendar grid, today view integration, sentence-format creation
- **Workout** — Hevy-inspired gym logger. Routines, exercise picker with muscle/equipment filters, active workout session with live timer, set tracking (weight/reps), workout history. Seeded with ~38 exercises.
- **Feature system** — protocol-based plugin architecture with `FeatureDefinition`, `FeatureRegistry`, `FeatureConfig` (SwiftData toggle), and `FeatureLink` for cross-referencing
- **Sidebar** — custom drawer with interactive drag (follows thumb), edge-swipe open/close, spring animations

**Not yet built (out of MVP scope):**

- User accounts / auth / cloud sync
- Notifications / alarms
- Data import/export
- Widgets
- Future modules: pomodoro, calendar, budget, cooking, weather, reading, meditation, lighting, meeting transcription

## Architecture

### Feature Plugin System

Every feature conforms to a `FeatureDefinition` structure and is registered in `FeatureRegistry` at app launch. The sidebar reads `FeatureConfig` records from SwiftData to determine which features are visible.

```
FeatureKey (enum) → FeatureDefinition (struct) → FeatureRegistry (static array)
                                                      ↓
                                               SidebarView reads FeatureConfig @Query
                                                      ↓
                                               ContentView routes SidebarDestination → View
```

Adding a new feature:
1. Add a case to `FeatureKey`
2. Create a `FeatureDefinition` with key, display name, and SF Symbol icon
3. Register it in `LastAppApp.init()`
4. Add its SwiftData models to the `Schema` in `LastAppApp`
5. Add a `SidebarDestination` case
6. Route it in `ContentView.destinationView`

### Navigation

`ContentView` is a root `ZStack`:
- `NavigationStack` as the main content (swaps root view based on `AppState.selectedDestination`)
- Dimming overlay + `SidebarView` sliding in from the left
- Edge hot zones for swipe-to-open (left, 30pt) and swipe-to-close (right, 64pt)

`SidebarDestination` enum cases: `.inbox`, `.today`, `.upcoming`, `.completed`, `.list(UUID)`, `.habits`, `.workout`, `.settings`

### Data Layer

Single `ModelContainer` configured at app entry in `LastAppApp`. All SwiftData models are co-located with their feature under `Features/`. Smart lists (Inbox, Today, etc.) use computed `@Query` predicates — they are not stored separately.

Key models:
- **TaskItem** / **TaskList** — tasks with priority, tags, subtasks (one level), optional list assignment
- **Habit** / **HabitLog** / **HabitStack** / **HabitStackEntry** — habits with computed streaks, stackable habit chains
- **Exercise** / **Routine** / **RoutineEntry** / **WorkoutSession** / **SessionExercise** / **SessionSet** — workout logging with routines and per-set tracking
- **FeatureConfig** — per-feature enable/disable toggle
- **FeatureLink** — generic cross-reference between any two feature items (sourceType/sourceId → targetType/targetId)

## Project Structure

```
LastApp/
  LastApp/
    LastAppApp.swift              # @main, ModelContainer, feature registration, seed data
    ContentView.swift             # Root ZStack — sidebar + NavigationStack routing
    Core/
      AppState.swift              # @Observable — selectedDestination, isSidebarOpen
      Features/
        FeatureKey.swift          # Enum: tasks, habits, workout
      Navigation/
        SidebarView.swift         # Drawer UI, reads FeatureConfig via @Query
        SidebarDestination.swift  # Enum for all navigation targets
      Settings/
        SettingsView.swift
        FeatureToggleView.swift   # Toggle features on/off
    Features/
      Tasks/
        TasksFeature.swift        # FeatureDefinition
        Models/                   # TaskItem, TaskList, Priority
        Views/                    # TaskListView, TaskRowView, TaskDetailView, TaskCreationView, TodayView
        ViewModels/               # TaskViewModel
      Habits/
        HabitsFeature.swift       # FeatureDefinition
        HabitNotificationManager.swift
        Models/                   # Habit, HabitLog, HabitStack, HabitStackEntry
        Views/                    # HabitListView, HabitRowView, HabitDetailView, HabitCreationView, HabitStackView, HabitStackRowView
        ViewModels/               # HabitViewModel
      Workout/
        WorkoutFeature.swift      # FeatureDefinition
        WorkoutSeedData.swift     # ~38 seeded exercises
        Models/                   # Exercise, Equipment, MuscleGroup, Routine, RoutineEntry, WorkoutSession, SessionExercise, SessionSet
        Views/                    # WorkoutListView, ActiveWorkoutView, RoutineBuilderView, ExercisePickerView, ExerciseDetailView, WorkoutSessionDetailView
    Shared/
      Theme/
        AppTheme.swift            # Teal accent (#14b8a6), priority colors, layout constants
      Extensions/
        Date+Helpers.swift
      Models/
        FeatureConfig.swift
        FeatureLink.swift
  LastApp.xcodeproj/
docs/
  superpowers/
    specs/                        # Design specs (MVP, workout)
    plans/                        # Implementation plans
prompt.md                         # Original project prompt and requirements
```

## Design Decisions

| Decision | Choice |
|---|---|
| Accent color | Teal `#14b8a6` |
| Appearance | Adaptive (follows system dark/light) |
| Priority system | P1–P4 with red/orange/blue/gray colors (TickTick convention) |
| Sidebar | Custom drawer, not `NavigationSplitView` — full control over gestures and animation |
| Smart lists | Computed `@Query` predicates, not materialized |
| Habit streaks | Computed on read from `HabitLog`, not stored |
| Subtasks | One level deep only |
| ViewModels | `@Observable` classes (Swift Observation), not `ObservableObject` |
| Workout sets | Per-set weight/reps tracking (Hevy-style) |
| Exercise library | Seeded at first launch, users can add custom exercises |

## References

- **TickTick** — primary UX inspiration for task management and sidebar navigation
- **Hevy** — reference for workout tracking UI and session flow
- **Atomic Habits** — inspiration for habit stacking feature

## Development

Open `LastApp/LastApp.xcodeproj` in Xcode. Build target is iOS 17+. No external dependencies — everything uses Apple frameworks (SwiftUI, SwiftData).
