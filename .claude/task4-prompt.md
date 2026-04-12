You are implementing Task 4 of the LastApp iOS project: App entry point and ModelContainer.

## Context

Tasks 1-3 complete. The following exist:
- Priority, Frequency, AppTheme, Date+Helpers (Task 1)
- SwiftData models: TaskItem, TaskList, Habit, HabitLog, FeatureConfig, FeatureLink (Task 2)
- FeatureKey, FeatureDefinition, FeatureRegistry, AppState, SidebarDestination (Task 3)

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`
- The generated `LastAppApp.swift` and `ContentView.swift` are at `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/LastAppApp.swift` and `ContentView.swift` — REPLACE their contents.

## Files to modify/create

- Modify: `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/LastAppApp.swift` (replace)
- Modify: `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` (replace with stub)
- Create: `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/TasksFeature.swift` (stub)
- Create: `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/HabitsFeature.swift` (stub)

## Step 1: Check existing file locations

```bash
find /Users/jay/dev/last-app/LastApp/LastApp -name "LastAppApp.swift" -o -name "ContentView.swift" | sort
```

## Step 2: Write TasksFeature.swift (compile stub)

```swift
// LastApp/Features/Tasks/TasksFeature.swift
import SwiftUI

enum TasksFeature {
    static let definition = FeatureDefinition(
        key: .tasks,
        displayName: "Tasks",
        icon: "checkmark.circle",
        isAlwaysOn: true,
        makeSidebarRow: { _, _ in AnyView(EmptyView()) },
        makeRootView: { _ in AnyView(EmptyView()) }
    )
}
```

## Step 3: Write HabitsFeature.swift (compile stub)

```swift
// LastApp/Features/Habits/HabitsFeature.swift
import SwiftUI

enum HabitsFeature {
    static let definition = FeatureDefinition(
        key: .habits,
        displayName: "Habits",
        icon: "flame",
        isAlwaysOn: false,
        makeSidebarRow: { _, _ in AnyView(EmptyView()) },
        makeRootView: { _ in AnyView(EmptyView()) }
    )
}
```

## Step 4: Replace ContentView.swift with stub

Find the ContentView.swift file location from Step 1, then replace its contents:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Text("LastApp — scaffold")
            .padding()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
```

## Step 5: Replace LastAppApp.swift

Find the LastAppApp.swift file location from Step 1, then replace its contents:

```swift
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
```

## Step 6: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

Expected: BUILD SUCCEEDED. If errors, read and fix them.

## Step 7: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

Expected: All existing tests still pass.

## Step 8: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 4: Wire app entry point, ModelContainer, TasksFeature/HabitsFeature stubs"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
