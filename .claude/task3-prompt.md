You are implementing Task 3 of the LastApp iOS project: App state, navigation types, and feature system.

## Context

LastApp is a native iOS SwiftUI + SwiftData productivity app. Tasks 1 and 2 are complete:
- Priority, Frequency, AppTheme, Date+Helpers exist
- SwiftData models (TaskItem, TaskList, Habit, HabitLog, FeatureConfig, FeatureLink) exist
- FeatureKey.swift was created in Task 2 at `/Users/jay/dev/last-app/LastApp/LastApp/Core/Features/FeatureKey.swift`

**Key facts:**
- Xcode 16: files on disk are auto-included (PBXFileSystemSynchronizedRootGroup)
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Core/Features/FeatureDefinition.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Core/Features/FeatureRegistry.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Core/Navigation/SidebarDestination.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Core/AppState.swift`

**Note:** FeatureKey.swift already exists. Do NOT recreate it.

## Step 1: Check if FeatureKey.swift exists

```bash
cat /Users/jay/dev/last-app/LastApp/LastApp/Core/Features/FeatureKey.swift
```

If it doesn't exist, create it:
```swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
}
```

## Step 2: Write SidebarDestination.swift

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
    case settings
}
```

## Step 3: Write AppState.swift

```swift
// LastApp/Core/AppState.swift
import SwiftUI

@Observable
final class AppState {
    var selectedDestination: SidebarDestination = .inbox
    var isSidebarOpen: Bool = false

    func navigate(to destination: SidebarDestination) {
        selectedDestination = destination
        isSidebarOpen = false
    }
}
```

## Step 4: Write FeatureDefinition.swift

```swift
// LastApp/Core/Features/FeatureDefinition.swift
import SwiftUI

struct FeatureDefinition {
    let key: FeatureKey
    let displayName: String
    let icon: String
    let isAlwaysOn: Bool
    let makeSidebarRow: (_ isSelected: Bool, _ onSelect: @escaping () -> Void) -> AnyView
    let makeRootView: (_ appState: AppState) -> AnyView
}
```

## Step 5: Write FeatureRegistry.swift

```swift
// LastApp/Core/Features/FeatureRegistry.swift
import Foundation

enum FeatureRegistry {
    private(set) static var all: [FeatureDefinition] = []

    static func register(_ definition: FeatureDefinition) {
        guard !all.contains(where: { $0.key == definition.key }) else { return }
        all.append(definition)
    }

    static func definition(for key: FeatureKey) -> FeatureDefinition? {
        all.first { $0.key == key }
    }
}
```

## Step 6: Build to verify

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

Expected: BUILD SUCCEEDED

## Step 7: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 3: Add AppState, SidebarDestination, FeatureDefinition, FeatureRegistry"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build result
- Files changed
- Any concerns
