# LastApp — Project Prompt

## What are you building?

LastApp — an all-in-one productivity iOS app that replaces the need for multiple daily-use apps. The core is a TickTick-inspired task management system with a modular architecture where additional features (habits, workouts, budget, cooking, etc.) can be toggled on/off and appear in a sidebar.

Apps being replaced:
- To-do lists, alarms/reminders, weather, calendar, workout, cooking, groceries, shopping, habit tracker, fitness, budgeting, reading, meditating, lighting automation, meeting note-taking/transcribing

## Who is it for?

Building for myself first, but designed so it could work for anyone tired of juggling multiple productivity apps. Solves the problem of needing a dozen apps just to stay organized and productive.

## What does success look like?

When I can use LastApp as my single daily-driver app and delete all the individual apps it replaces.

## What are the core features?

**Core system (TickTick-inspired):**
- Task/to-do lists with inbox, custom lists, and smart lists (Today, Upcoming, Completed)
- Task creation with title, notes, due date, priority, tags, subtasks
- Drag-to-reorder, quick-add, search and filter

**Modular feature system:**
- Features can be enabled/disabled from settings
- Enabled features appear in the sidebar
- Cross-referencing between tasks and feature items (e.g., a task can link to a habit or workout)

**MVP features (beyond core tasks):**
- Habit tracker (daily/weekly habits, streak tracking, check-off from daily view)

**Future features (post-MVP):**
- Pomodoro timer, calendar, Eisenhower matrix, countdown
- Workout tracker, cooking/recipes, budget tracker
- Weather, reading, meditation, lighting automation
- Meeting note-taking/transcribing, alarms/reminders

## What's out of scope for MVP?

- User accounts / login / cloud sync
- Android or web versions
- All feature modules beyond tasks + habits
- Notifications / alarms
- Data import/export
- Widgets

## What's the tech stack?

- **Platform:** iOS (native)
- **Frontend:** SwiftUI
- **Persistence:** SwiftData (local SQLite, offline by default)
- **Architecture:** MVVM with modular feature system
- **Minimum iOS target:** iOS 17
- **Future auth/sync:** Design data models for per-user ownership; add CloudKit or Supabase later

## Are there existing constraints?

- **Timeline:** As fast as possible
- **Team:** Solo developer (fullstack background), AI-assisted
- **Budget:** No budget constraints for MVP (no paid services needed)
- **Offline:** Nice to have (SwiftData gives this for free)

## What does the data look like?

**Core models:**
- **TaskItem** — id, title, notes, dueDate, priority, isCompleted, list, subtasks, tags, featureLinks
- **TaskList** — id, name, icon, color, sortOrder
- **Habit** — id, name, frequency, reminderTime, createdAt
- **HabitLog** — id, habitId, date, isCompleted
- **FeatureConfig** — id, featureKey, isEnabled, sortOrder
- **FeatureLink** — id, sourceType, sourceId, targetType, targetId

All data is local-first via SwiftData. Designed so auth and cloud sync can be layered on later without major refactoring.

## Are there UI/UX requirements?

- TickTick is the primary UI reference — clean sidebar navigation, quick-add, list-based views
- Aiming for simple and user-friendly over feature-rich
- No specific branding or design system yet — get it working first, polish later

**UI Implementation Requirement:** When building or modifying any UI, you MUST use the `frontend-design` skill (located at `skills/frontend-design/SKILL.md`). Before writing any view code:
1. Think through the design context — purpose, tone, constraints, differentiation
2. Commit to a bold, intentional aesthetic direction (not generic AI defaults)
3. Choose distinctive typography, a cohesive color palette, and purposeful motion/spatial composition
4. Avoid generic patterns — no default system fonts, no cliched purple gradients, no cookie-cutter layouts
5. Every screen should feel designed for this specific app, not generated from a template

## What are the biggest risks or unknowns?

- Each feature needs to be as good as the app it replaces, but the overall experience should be simpler
- Modular cross-referencing system needs to be designed carefully to stay flexible without becoming complex
- Scope creep — the feature list is large; discipline on MVP boundaries is critical

## Are there similar products or references?

- **TickTick** — primary inspiration for core UX and modular feature toggling
- **Hevy, PUSH, Strong** — references for workout tracking (future feature)

## What's the priority order?

1. Core to-do / task system
2. Habit tracker
3. Modular feature framework (toggle, sidebar, cross-referencing)
4. Additional features one at a time

## Project structure

```
LastApp/
  App/
    LastAppApp.swift
    ContentView.swift
  Core/
    Features/
      FeatureProtocol.swift
      FeatureRegistry.swift
      FeatureLink.swift
    Navigation/
      SidebarView.swift
      AppTabView.swift
    Settings/
      SettingsView.swift
      FeatureToggleView.swift
  Features/
    Tasks/
      Models/
        TaskItem.swift
        TaskList.swift
      Views/
        TaskListView.swift
        TaskDetailView.swift
        TaskCreationView.swift
      ViewModels/
        TaskViewModel.swift
    Habits/
      Models/
        Habit.swift
        HabitLog.swift
      Views/
        HabitListView.swift
        HabitDetailView.swift
      ViewModels/
        HabitViewModel.swift
  Shared/
    Components/
    Extensions/
    Theme/
```
