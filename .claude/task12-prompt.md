You are implementing Task 12 of the LastApp iOS project: Settings, feature toggle, and feature wiring.

## Context

Tasks 1-11 complete. ContentView has a stub `SettingsView`. This is the final task — replace that stub, add real feature implementations for TasksFeature and HabitsFeature, and wire up Settings.

**Design direction:**
- SettingsView: plain List with a "Features" section listing toggleable modules, and an About section with version
- FeatureToggleView: icon + name + Toggle (or "Always on" label for Tasks). Teal toggle tint.
- Clean, functional — not a feature showcase

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Core/Settings/SettingsView.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Core/Settings/FeatureToggleView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` — remove `struct SettingsView` stub
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/TasksFeature.swift` — replace stub with real implementation
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/HabitsFeature.swift` — replace stub with real implementation

## Step 1: Write FeatureToggleView.swift

```swift
// LastApp/Core/Settings/FeatureToggleView.swift
import SwiftUI

struct FeatureToggleView: View {
    let definition: FeatureDefinition
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: definition.icon)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(width: 28, alignment: .center)

            Text(definition.displayName)
                .font(.system(.body))

            Spacer()

            if definition.isAlwaysOn {
                Text("Always on")
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)
            } else {
                Toggle("", isOn: $isEnabled)
                    .tint(Color.appAccent)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 2)
    }
}
```

## Step 2: Write SettingsView.swift

```swift
// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]

    var body: some View {
        List {
            Section("Features") {
                ForEach(FeatureRegistry.all, id: \.key) { definition in
                    if let config = featureConfigs.first(where: { $0.featureKey == definition.key }) {
                        FeatureToggleView(
                            definition: definition,
                            isEnabled: Binding(
                                get: { config.isEnabled },
                                set: { config.isEnabled = $0 }
                            )
                        )
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [FeatureConfig.self], inMemory: true)
}
```

## Step 3: Replace TasksFeature.swift with real implementation

```swift
// LastApp/Features/Tasks/TasksFeature.swift
import SwiftUI

enum TasksFeature {
    static let definition = FeatureDefinition(
        key: .tasks,
        displayName: "Tasks",
        icon: "checkmark.circle",
        isAlwaysOn: true,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Tasks", systemImage: "checkmark.circle")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(TaskListView())
        }
    )
}
```

## Step 4: Replace HabitsFeature.swift with real implementation

```swift
// LastApp/Features/Habits/HabitsFeature.swift
import SwiftUI

enum HabitsFeature {
    static let definition = FeatureDefinition(
        key: .habits,
        displayName: "Habits",
        icon: "flame",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Habits", systemImage: "flame")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(HabitListView())
        }
    )
}
```

## Step 5: Remove SettingsView stub from ContentView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` and remove:
```swift
struct SettingsView: View { var body: some View { Text("Settings").navigationTitle("Settings") } }
```

After this, ContentView.swift should have no stubs remaining.

## Step 6: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

Fix any errors before proceeding.

## Step 7: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

Expected: All 16 tests pass.

## Step 8: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 12: Add SettingsView, FeatureToggleView, wire TasksFeature and HabitsFeature"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
