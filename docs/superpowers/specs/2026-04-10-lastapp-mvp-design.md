# LastApp MVP — Design Spec
_Date: 2026-04-10_

## Overview

LastApp is a native iOS productivity app (SwiftUI + SwiftData, iOS 17+) that replaces multiple single-purpose apps. The MVP delivers a core task management system and a habit tracker, wrapped in a modular feature framework that makes adding future modules straightforward.

---

## Decisions

| Decision | Choice |
|---|---|
| Navigation | Custom sidebar drawer (ZStack overlay, slide-in from left) |
| Appearance | Adaptive — follows system dark/light mode |
| Accent color | Teal `#14b8a6` |
| Scaffold approach | Manual Xcode project (user creates), source files generated |
| State management | `@Observable` AppState + SwiftData `@Query` |
| Smart lists | Computed `@Query` predicates, not stored in DB |
| Feature system | Protocol + static registry + `FeatureConfig` SwiftData toggle |
| Priority system | P1–P4 (red/orange/blue/none), TickTick convention |
| Subtasks | One level deep, MVP only |
| Habit streaks | Computed on read from `HabitLog`, not stored |
| Today view | Combined tasks + habits summary in one view |

---

## Architecture & Data Layer

**Pattern:** MVVM. Single `ModelContainer` configured at app entry point via `.modelContainer()`. All SwiftData models co-located with their feature (no shared root Models folder).

### SwiftData Models

**TaskItem**
- `id: UUID`
- `title: String`
- `notes: String`
- `dueDate: Date?`
- `priority: Priority` (enum: p1/p2/p3/p4)
- `isCompleted: Bool`
- `sortOrder: Int`
- `tags: [String]`
- `list: TaskList?` (relationship — nil = Inbox)
- `subtasks: [TaskItem]` (self-relationship, one level only)

**TaskList**
- `id: UUID`
- `name: String`
- `icon: String` (SF Symbol name)
- `color: String` (hex)
- `sortOrder: Int`
- `tasks: [TaskItem]` (relationship)

**Habit**
- `id: UUID`
- `name: String`
- `frequency: Frequency` (enum: daily/weekly)
- `createdAt: Date`
- `logs: [HabitLog]` (relationship)
- `streak: Int` — computed property, not stored

**HabitLog**
- `id: UUID`
- `date: Date`
- `isCompleted: Bool`
- `habit: Habit` (relationship)

**FeatureConfig**
- `id: UUID`
- `featureKey: FeatureKey` (enum: tasks/habits/…)
- `isEnabled: Bool`
- `sortOrder: Int`

**FeatureLink**
- `id: UUID`
- `sourceType: String`
- `sourceId: String`
- `targetType: String`
- `targetId: String`

### ViewModels

`@Observable` classes (Swift Observation framework, not `ObservableObject`). Each feature owns its ViewModel. Global app state lives in `AppState`.

---

## Navigation & UI Structure

**ContentView** — root `ZStack`:
1. `MainContentView` — full screen, hosts `NavigationStack` whose root swaps on `selectedDestination`
2. Sidebar overlay — slides in from left on hamburger tap, dims content behind it

**AppState** (`@Observable`, injected via environment):
```swift
var selectedDestination: SidebarDestination
var isSidebarOpen: Bool
var enabledFeatures: [FeatureConfig]  // sourced from SwiftData
```

**SidebarDestination** enum:
- `.inbox`, `.today`, `.upcoming`, `.completed`
- `.list(TaskList)`
- `.habits`

**Sidebar contents (top to bottom):**
1. Smart lists: Inbox · Today · Upcoming · Completed
2. Divider + user's custom TaskLists (drag-to-reorder)
3. Divider + enabled feature modules (Habits for MVP)
4. Bottom: Settings

**Task creation:** FAB (`+` button) bottom-right. Opens a sheet in quick-add mode (title + date shortcuts + priority). Expandable to full detail mode via chevron.

**Task detail:** Pushed via `NavigationStack` on row tap. Inline editing for all fields.

---

## Query Predicates (Smart Lists)

| Destination | Predicate |
|---|---|
| Inbox | `list == nil && isCompleted == false` |
| Today | `dueDate <= endOfToday && isCompleted == false` |
| Upcoming | `dueDate > endOfToday && isCompleted == false` |
| Completed | `isCompleted == true` (last 30 days) |
| Custom list | `list == selectedList && isCompleted == false` |

---

## Feature Module System

```swift
protocol AppFeature {
    static var key: FeatureKey { get }
    static var displayName: String { get }
    static var icon: String { get }  // SF Symbol
    @ViewBuilder static func sidebarRow() -> some View
    @ViewBuilder static func rootView() -> some View
}
```

`FeatureRegistry` holds a static array of all known `AppFeature` types. The sidebar reads `FeatureConfig` via `@Query`, filters `isEnabled == true`, maps to registry for views.

**MVP registered features:** `TasksFeature` (always on), `HabitsFeature` (toggleable, on by default).

Toggling in Settings flips `FeatureConfig.isEnabled` → sidebar updates automatically.

---

## Task System

**Row:** completion circle (tap = complete) · title · priority dot · due date chip · swipe-left to delete · drag handle for reorder.

**Quick-add sheet fields:** title · Today/Tomorrow/Next Week shortcuts · P1–P4 priority · expand button.

**Full detail fields:** title · notes · due date (date picker) · priority · tags (chip input) · list picker · subtasks (add/remove inline).

**Priority colors:** P1 red `#ef4444` · P2 orange `#f97316` · P3 blue `#3b82f6` · P4 gray `#6b7280`.

**Tags:** `[String]` on TaskItem, free-text chip entry in detail view. No global tag management MVP.

**Subtasks:** Flat list within TaskDetailView. Each subtask is a `TaskItem` with a parent relationship. One level only.

---

## Habit Tracker

**HabitListView:** All habits, each row shows name · frequency · streak count · today's check circle.

**Streak:** Computed on `Habit` by walking `HabitLog` backward from today. Daily: stops at first missed calendar day. Weekly: checks current ISO week.

**HabitDetailView:** Name · frequency · 30-day calendar grid (filled = completed, empty = missed). Inline edit.

**HabitCreationView:** Sheet with name + frequency picker. No reminder time (notifications out of MVP scope).

**Today view integration:** Habits section at top of Today view — shows habits due today with inline check-off alongside the task list.

---

## Project Structure

```
LastApp/
  App/
    LastAppApp.swift          # @main, ModelContainer setup
    ContentView.swift         # Root ZStack (sidebar + content)
  Core/
    AppState.swift            # @Observable global state
    Features/
      AppFeature.swift        # Protocol
      FeatureRegistry.swift   # Static registry
      FeatureKey.swift        # Enum
    Navigation/
      SidebarView.swift
      SidebarDestination.swift
    Settings/
      SettingsView.swift
      FeatureToggleView.swift
  Features/
    Tasks/
      Models/
        TaskItem.swift
        TaskList.swift
        Priority.swift
      Views/
        TaskListView.swift
        TaskRowView.swift
        TaskDetailView.swift
        TaskCreationView.swift
      ViewModels/
        TaskViewModel.swift
    Habits/
      Models/
        Habit.swift
        HabitLog.swift
        Frequency.swift
      Views/
        HabitListView.swift
        HabitRowView.swift
        HabitDetailView.swift
        HabitCreationView.swift
      ViewModels/
        HabitViewModel.swift
  Shared/
    Theme/
      AppTheme.swift          # Colors, teal accent, semantic tokens
    Extensions/
      Date+Helpers.swift
    Models/
      FeatureConfig.swift
      FeatureLink.swift
```

---

## Out of Scope (MVP)

- User accounts, login, cloud sync
- Android/web
- Notifications/alarms
- Data import/export
- Widgets
- Any feature module beyond Tasks + Habits
- Pomodoro, calendar, workout, cooking, budget, weather, reading, meditation, lighting, meeting transcription
