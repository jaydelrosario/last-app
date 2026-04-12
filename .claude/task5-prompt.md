You are implementing Task 5 of the LastApp iOS project: Sidebar view and ContentView drawer.

## Context

Tasks 1-4 complete. The app compiles with a scaffold ContentView. Now building the sidebar drawer UI.

**Design direction (already decided in brainstorming):**
- Sidebar drawer slides in from the left over main content (ZStack overlay pattern)
- Teal accent #14b8a6 for selected state
- Adaptive dark/light mode (system)
- SF Rounded for section headers, SF default for rows
- Clean, minimal, TickTick-inspired — no decorative clutter
- Selected row: teal text + teal 12% opacity background pill
- Section headers: small caps, tertiary color

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create/modify

- Create: `/Users/jay/dev/last-app/LastApp/LastApp/Core/Navigation/SidebarView.swift`
- Modify: `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` (replace stub with full drawer)

## Step 1: Write SidebarView.swift

```swift
// LastApp/Core/Navigation/SidebarView.swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]
    @Query(filter: #Predicate<FeatureConfig> { $0.isEnabled }, sort: \FeatureConfig.sortOrder)
    private var enabledFeatures: [FeatureConfig]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    smartListsSection
                    if !customLists.isEmpty {
                        sectionLabel("LISTS")
                        customListsSection
                    }
                    enabledFeaturesSection
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            Spacer()
            settingsRow
        }
        .frame(width: AppTheme.sidebarWidth)
        .background(.regularMaterial)
    }

    // MARK: - Sections

    private var sidebarHeader: some View {
        Text("LastApp")
            .font(.system(.title2, design: .rounded, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
    }

    private var smartListsSection: some View {
        Group {
            sidebarRow(icon: "tray", label: "Inbox", destination: .inbox)
            sidebarRow(icon: "sun.max", label: "Today", destination: .today)
            sidebarRow(icon: "calendar", label: "Upcoming", destination: .upcoming)
            sidebarRow(icon: "checkmark.circle", label: "Completed", destination: .completed)
        }
    }

    private var customListsSection: some View {
        ForEach(customLists) { list in
            sidebarRow(icon: list.icon, label: list.name, destination: .list(list.id))
        }
    }

    private var enabledFeaturesSection: some View {
        ForEach(enabledFeatures, id: \.id) { config in
            if let feature = FeatureRegistry.definition(for: config.featureKey),
               !feature.isAlwaysOn {
                sectionLabel(feature.displayName.uppercased())
                sidebarRow(
                    icon: feature.icon,
                    label: feature.displayName,
                    destination: destinationFor(config.featureKey)
                )
            }
        }
    }

    private var settingsRow: some View {
        Button {
            appState.navigate(to: .settings)
        } label: {
            Label("Settings", systemImage: "gearshape")
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sidebarRow(icon: String, label: String, destination: SidebarDestination) -> some View {
        let isSelected = appState.selectedDestination == destination
        return Button {
            appState.navigate(to: destination)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(isSelected ? Color.appAccent : .primary)
                Text(label)
                    .font(.system(.body))
                    .foregroundStyle(isSelected ? Color.appAccent : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.appAccent.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func destinationFor(_ key: FeatureKey) -> SidebarDestination {
        switch key {
        case .tasks: .inbox
        case .habits: .habits
        }
    }
}
```

## Step 2: Replace ContentView.swift with full drawer implementation

Find the ContentView.swift (likely at `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift`) and replace:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appState.isSidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { appState.isSidebarOpen = false }
                    .transition(.opacity)
            }

            if appState.isSidebarOpen {
                SidebarView()
                    .ignoresSafeArea()
                    .transition(.move(edge: .leading))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 8, y: 0)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: appState.isSidebarOpen)
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            destinationView
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            appState.isSidebarOpen.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(.body, weight: .medium))
                        }
                        .tint(.primary)
                    }
                }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch appState.selectedDestination {
        case .inbox, .upcoming, .completed, .list:
            TaskListView()
        case .today:
            TodayView()
        case .habits:
            HabitListView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Stubs (removed as real views are implemented in later tasks)
struct TaskListView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        Text(navigationTitle)
            .navigationTitle(navigationTitle)
    }
    private var navigationTitle: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .list: "List"
        default: ""
        }
    }
}
struct TodayView: View { var body: some View { Text("Today").navigationTitle("Today") } }
struct HabitListView: View { var body: some View { Text("Habits").navigationTitle("Habits") } }
struct SettingsView: View { var body: some View { Text("Settings").navigationTitle("Settings") } }

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, TaskList.self, Habit.self, HabitLog.self, FeatureConfig.self, FeatureLink.self], inMemory: true)
}
```

## Step 3: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

Fix any errors. Common issue: if `TaskListView` conflicts with an existing definition anywhere, resolve it.

## Step 4: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

## Step 5: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 5: Add SidebarView and ContentView ZStack drawer navigation"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
