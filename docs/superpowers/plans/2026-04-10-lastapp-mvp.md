# LastApp MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **UI tasks:** Any task that creates or modifies a SwiftUI view MUST invoke the `frontend-design` skill before writing view code. This is a hard requirement from the project spec.

**Goal:** Build a native iOS productivity app (SwiftUI + SwiftData) with a core task system, habit tracker, and modular feature framework.

**Architecture:** MVVM with `@Observable` ViewModels and AppState; SwiftData for persistence; custom sidebar drawer navigation; feature modules registered via a static registry.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, iOS 17+, XCTest

---

## Prerequisites

Before starting Task 1, the user must:
1. Open Xcode → File → New → Project → App
2. Set: Product Name `LastApp`, Interface `SwiftUI`, Language `Swift`, Storage `None` (skip wizard SwiftData boilerplate), check `Include Tests`
3. Save to `/Users/jay/dev/last-app/`
4. Close any generated "ContentView" preview canvas

This produces:
- `/Users/jay/dev/last-app/LastApp.xcodeproj`
- `/Users/jay/dev/last-app/LastApp/` (source root — contains generated `LastAppApp.swift`, `ContentView.swift`, `Assets.xcassets`)
- `/Users/jay/dev/last-app/LastAppTests/LastAppTests.swift`

**Note on adding files to Xcode:** Xcode doesn't auto-detect new Swift files on disk. After each task that creates new files, the plan includes a step to add them to the Xcode project. Do this by right-clicking the appropriate group in the Xcode navigator → "Add Files to LastApp..." → select the new file(s) → ensure "LastApp target" is checked → Add.

---

## File Map

### Created (new files)

```
LastApp/
  App/
    LastAppApp.swift                    # @main, ModelContainer, AppState injection, feature registration
    ContentView.swift                   # Root ZStack: sidebar overlay + NavigationStack main area
  Core/
    AppState.swift                      # @Observable: selectedDestination, isSidebarOpen
    Features/
      FeatureKey.swift                  # Enum: .tasks, .habits
      FeatureDefinition.swift           # Struct: key, displayName, icon, isAlwaysOn, view factories
      FeatureRegistry.swift             # Static array, register(), definition(for:)
    Navigation/
      SidebarDestination.swift          # Enum: .inbox, .today, .upcoming, .completed, .list(UUID), .habits, .settings
      SidebarView.swift                 # Sidebar drawer contents
    Settings/
      SettingsView.swift                # Feature toggle list
      FeatureToggleView.swift           # Single feature toggle row
  Features/
    Tasks/
      Models/
        Priority.swift                  # Enum P1-P4 with label; colors live in AppTheme
        TaskItem.swift                  # @Model: SwiftData task entity
        TaskList.swift                  # @Model: SwiftData list entity
      ViewModels/
        TaskViewModel.swift             # @Observable: create, complete, delete, reorder tasks
      Views/
        TaskListView.swift              # List + query predicate for active destination
        TaskRowView.swift               # Single task row: circle, title, priority dot, date chip
        TaskDetailView.swift            # Full task editing view
        TaskCreationView.swift          # Quick-add sheet with expand toggle
        TodayView.swift                 # Today: habits summary + task list combined
      TasksFeature.swift               # FeatureDefinition factory for .tasks
    Habits/
      Models/
        Frequency.swift                 # Enum: .daily, .weekly
        Habit.swift                     # @Model: SwiftData habit entity, streak computed property
        HabitLog.swift                  # @Model: SwiftData log entry
      ViewModels/
        HabitViewModel.swift            # @Observable: create, toggle log, delete habits
      Views/
        HabitListView.swift             # List of habits with today check-off
        HabitRowView.swift              # Single habit row: name, streak, check circle
        HabitDetailView.swift           # 30-day calendar grid, inline edit
        HabitCreationView.swift         # Sheet: name + frequency picker
      HabitsFeature.swift              # FeatureDefinition factory for .habits
  Shared/
    Theme/
      AppTheme.swift                    # Color extensions: .appAccent (#14b8a6), .priorityColor(_:)
    Extensions/
      Date+Helpers.swift                # startOfDay, endOfDay, isToday, shortFormatted, etc.
    Models/
      FeatureConfig.swift               # @Model: feature enabled/sortOrder stored in SwiftData
      FeatureLink.swift                 # @Model: loose cross-feature link table
```

### Modified (replace generated content)

```
LastApp/LastAppApp.swift       # Replace with our version (keeps same filename Xcode expects)
LastApp/ContentView.swift      # Replace with our version
LastAppTests/LastAppTests.swift # Add test classes
```

---

## Task 1: Shared theme, enums, and date helpers

**Files:**
- Create: `LastApp/Shared/Theme/AppTheme.swift`
- Create: `LastApp/Shared/Extensions/Date+Helpers.swift`
- Create: `LastApp/Features/Tasks/Models/Priority.swift`
- Create: `LastApp/Features/Habits/Models/Frequency.swift`
- Modify: `LastAppTests/LastAppTests.swift`

- [ ] **Step 1: Create directory structure on disk**

```bash
mkdir -p /Users/jay/dev/last-app/LastApp/Shared/Theme
mkdir -p /Users/jay/dev/last-app/LastApp/Shared/Extensions
mkdir -p /Users/jay/dev/last-app/LastApp/Shared/Models
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Tasks/Models
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Tasks/ViewModels
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Tasks/Views
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Habits/Models
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Habits/ViewModels
mkdir -p /Users/jay/dev/last-app/LastApp/Features/Habits/Views
mkdir -p /Users/jay/dev/last-app/LastApp/Core/Features
mkdir -p /Users/jay/dev/last-app/LastApp/Core/Navigation
mkdir -p /Users/jay/dev/last-app/LastApp/Core/Settings
mkdir -p /Users/jay/dev/last-app/LastApp/App
```

- [ ] **Step 2: Write failing tests for Priority and Date helpers**

Replace the contents of `LastAppTests/LastAppTests.swift`:

```swift
import XCTest
@testable import LastApp

// MARK: - Priority Tests

final class PriorityTests: XCTestCase {
    func test_allCases_count() {
        XCTAssertEqual(Priority.allCases.count, 4)
    }

    func test_labels() {
        XCTAssertEqual(Priority.p1.label, "High")
        XCTAssertEqual(Priority.p2.label, "Medium")
        XCTAssertEqual(Priority.p3.label, "Low")
        XCTAssertEqual(Priority.p4.label, "None")
    }

    func test_rawValues() {
        XCTAssertEqual(Priority.p1.rawValue, 1)
        XCTAssertEqual(Priority.p4.rawValue, 4)
    }

    func test_comparable() {
        XCTAssertTrue(Priority.p1 < Priority.p4)
    }
}

// MARK: - Date Helper Tests

final class DateHelperTests: XCTestCase {
    func test_startOfDay_isAtMidnight() {
        let date = Date()
        let start = date.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_isToday_forCurrentDate() {
        XCTAssertTrue(Date().isToday)
    }

    func test_isToday_forYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func test_shortFormatted_today() {
        XCTAssertEqual(Date().shortFormatted, "Today")
    }

    func test_shortFormatted_tomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(tomorrow.shortFormatted, "Tomorrow")
    }

    func test_isSameDay() {
        let a = Date()
        let b = Calendar.current.date(byAdding: .hour, value: 2, to: a)!
        XCTAssertTrue(a.isSameDay(as: b))
    }
}
```

- [ ] **Step 3: Write `Priority.swift`**

```swift
// LastApp/Features/Tasks/Models/Priority.swift
import Foundation

enum Priority: Int, Codable, CaseIterable, Comparable {
    case p1 = 1, p2 = 2, p3 = 3, p4 = 4

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .p1: "High"
        case .p2: "Medium"
        case .p3: "Low"
        case .p4: "None"
        }
    }
}
```

- [ ] **Step 4: Write `Frequency.swift`**

```swift
// LastApp/Features/Habits/Models/Frequency.swift
import Foundation

enum Frequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
}
```

- [ ] **Step 5: Write `Date+Helpers.swift`**

```swift
// LastApp/Shared/Extensions/Date+Helpers.swift
import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var comps = DateComponents()
        comps.day = 1
        comps.second = -1
        return Calendar.current.date(byAdding: comps, to: startOfDay)!
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }

    static var nextWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    }

    var shortFormatted: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        let fmt = DateFormatter()
        let sameYear = Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
        fmt.dateFormat = sameYear ? "MMM d" : "MMM d, yyyy"
        return fmt.string(from: self)
    }
}
```

- [ ] **Step 6: Write `AppTheme.swift`**

```swift
// LastApp/Shared/Theme/AppTheme.swift
import SwiftUI

// MARK: - App Colors
extension Color {
    /// Teal accent: #14b8a6
    static let appAccent = Color(red: 0.082, green: 0.722, blue: 0.647)

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .p1: Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
        case .p2: Color(red: 0.976, green: 0.451, blue: 0.086) // #f97316
        case .p3: Color(red: 0.231, green: 0.510, blue: 0.965) // #3b82f6
        case .p4: Color(red: 0.420, green: 0.447, blue: 0.502) // #6b7280
        }
    }
}

// MARK: - Layout Constants
enum AppTheme {
    static let padding: CGFloat = 16
    static let rowSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 10
    static let sidebarWidth: CGFloat = 280
}
```

- [ ] **Step 7: Add new files to Xcode project**

In Xcode:
1. Right-click the top-level `LastApp` group in the Project Navigator
2. "Add Files to LastApp..."
3. Select: `LastApp/Shared/` and `LastApp/Features/Tasks/Models/Priority.swift` and `LastApp/Features/Habits/Models/Frequency.swift`
4. Ensure "LastApp" target is checked, "Create groups" is selected
5. Add
6. Also add the modified `LastAppTests/LastAppTests.swift` (already in project, just saved)

- [ ] **Step 8: Run tests**

```bash
xcodebuild test \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:LastAppTests/PriorityTests \
  -only-testing:LastAppTests/DateHelperTests \
  2>&1 | grep -E "(PASS|FAIL|error:|warning:)" | head -30
```

Expected: All 8 tests PASS.

- [ ] **Step 9: Commit**

```bash
git add LastApp/Shared LastApp/Features/Tasks/Models/Priority.swift LastApp/Features/Habits/Models/Frequency.swift LastAppTests/LastAppTests.swift
git commit -m "Add theme, date helpers, Priority and Frequency enums with tests"
```

---

## Task 2: SwiftData models

**Files:**
- Create: `LastApp/Features/Tasks/Models/TaskItem.swift`
- Create: `LastApp/Features/Tasks/Models/TaskList.swift`
- Create: `LastApp/Features/Habits/Models/Habit.swift`
- Create: `LastApp/Features/Habits/Models/HabitLog.swift`
- Create: `LastApp/Shared/Models/FeatureConfig.swift`
- Create: `LastApp/Shared/Models/FeatureLink.swift`
- Modify: `LastAppTests/LastAppTests.swift` (add habit streak tests)

- [ ] **Step 1: Write failing streak tests**

Append to `LastAppTests/LastAppTests.swift`:

```swift
// MARK: - Habit Streak Tests

final class HabitStreakTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Habit.self, HabitLog.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func test_streak_noLogs_isZero() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        XCTAssertEqual(habit.streak, 0)
    }

    func test_streak_onlyToday_isOne() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        let log = HabitLog(date: Date(), isCompleted: true, habit: habit)
        context.insert(log)
        XCTAssertEqual(habit.streak, 1)
    }

    func test_streak_todayAndYesterday_isTwo() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        context.insert(HabitLog(date: Date(), isCompleted: true, habit: habit))
        context.insert(HabitLog(date: yesterday, isCompleted: true, habit: habit))
        XCTAssertEqual(habit.streak, 2)
    }

    func test_streak_gapBreaksStreak() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        context.insert(HabitLog(date: Date(), isCompleted: true, habit: habit))
        // yesterday missing — gap
        context.insert(HabitLog(date: twoDaysAgo, isCompleted: true, habit: habit))
        XCTAssertEqual(habit.streak, 1)
    }

    func test_isCompletedToday_true() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        context.insert(HabitLog(date: Date(), isCompleted: true, habit: habit))
        XCTAssertTrue(habit.isCompletedToday)
    }

    func test_isCompletedToday_false_whenNoLog() throws {
        let habit = Habit(name: "Test", frequency: .daily)
        context.insert(habit)
        XCTAssertFalse(habit.isCompletedToday)
    }
}
```

- [ ] **Step 2: Write `TaskItem.swift`**

```swift
// LastApp/Features/Tasks/Models/TaskItem.swift
import SwiftData
import Foundation

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date? = nil
    var priorityRaw: Int = Priority.p4.rawValue
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var sortOrder: Int = 0
    var tags: [String] = []

    @Relationship(deleteRule: .nullify) var list: TaskList?
    @Relationship(deleteRule: .cascade) var subtasks: [TaskItem] = []

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .p4 }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: Priority = .p4,
        list: TaskList? = nil
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.list = list
    }
}
```

- [ ] **Step 3: Write `TaskList.swift`**

```swift
// LastApp/Features/Tasks/Models/TaskList.swift
import SwiftData
import Foundation

@Model
final class TaskList {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "list.bullet"
    var colorHex: String = "14b8a6"
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list) var tasks: [TaskItem] = []

    init(name: String, icon: String = "list.bullet", colorHex: String = "14b8a6") {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
```

- [ ] **Step 4: Write `HabitLog.swift`**

Write this before `Habit.swift` because `Habit` references `HabitLog`:

```swift
// LastApp/Features/Habits/Models/HabitLog.swift
import SwiftData
import Foundation

@Model
final class HabitLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var isCompleted: Bool = true
    var habit: Habit?

    init(date: Date = Date(), isCompleted: Bool = true, habit: Habit) {
        self.date = date
        self.isCompleted = isCompleted
        self.habit = habit
    }
}
```

- [ ] **Step 5: Write `Habit.swift`**

```swift
// LastApp/Features/Habits/Models/Habit.swift
import SwiftData
import Foundation

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var frequencyRaw: String = Frequency.daily.rawValue
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit) var logs: [HabitLog] = []

    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Current streak. For daily: consecutive completed days ending today (or yesterday).
    /// For weekly: consecutive completed weeks ending this week (or last week).
    var streak: Int {
        let calendar = Calendar.current
        let completedDays = Set(
            logs.filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )

        switch frequency {
        case .daily:
            var count = 0
            var day = calendar.startOfDay(for: .now)
            // If today not done yet, start from yesterday so partial days don't break streak
            if !completedDays.contains(day) {
                day = calendar.date(byAdding: .day, value: -1, to: day)!
            }
            while completedDays.contains(day) {
                count += 1
                day = calendar.date(byAdding: .day, value: -1, to: day)!
            }
            return count

        case .weekly:
            var count = 0
            var referenceDate = Date()
            for _ in 0..<52 {
                guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { break }
                let hasLog = completedDays.contains { interval.contains($0) }
                guard hasLog else { break }
                count += 1
                referenceDate = calendar.date(byAdding: .day, value: -7, to: interval.start)!
            }
            return count
        }
    }

    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return logs.contains {
            $0.isCompleted && Calendar.current.startOfDay(for: $0.date) == today
        }
    }

    init(name: String, frequency: Frequency = .daily) {
        self.name = name
        self.frequencyRaw = frequency.rawValue
    }
}
```

- [ ] **Step 6: Write `FeatureConfig.swift`**

```swift
// LastApp/Shared/Models/FeatureConfig.swift
import SwiftData
import Foundation

@Model
final class FeatureConfig {
    var id: UUID = UUID()
    var featureKeyRaw: String = ""
    var isEnabled: Bool = true
    var sortOrder: Int = 0

    var featureKey: FeatureKey {
        get { FeatureKey(rawValue: featureKeyRaw) ?? .tasks }
        set { featureKeyRaw = newValue.rawValue }
    }

    init(featureKey: FeatureKey, isEnabled: Bool = true, sortOrder: Int = 0) {
        self.featureKeyRaw = featureKey.rawValue
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 7: Write `FeatureLink.swift`**

```swift
// LastApp/Shared/Models/FeatureLink.swift
import SwiftData
import Foundation

@Model
final class FeatureLink {
    var id: UUID = UUID()
    var sourceType: String = ""
    var sourceId: String = ""
    var targetType: String = ""
    var targetId: String = ""

    init(sourceType: String, sourceId: String, targetType: String, targetId: String) {
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.targetType = targetType
        self.targetId = targetId
    }
}
```

- [ ] **Step 8: Add new model files to Xcode project**

In Xcode, right-click each target folder and add:
- `LastApp/Features/Tasks/Models/TaskItem.swift` → add to LastApp target
- `LastApp/Features/Tasks/Models/TaskList.swift` → add to LastApp target
- `LastApp/Features/Habits/Models/Habit.swift` → add to LastApp target
- `LastApp/Features/Habits/Models/HabitLog.swift` → add to LastApp target
- `LastApp/Shared/Models/FeatureConfig.swift` → add to LastApp target
- `LastApp/Shared/Models/FeatureLink.swift` → add to LastApp target

Also add `LastAppTests/LastAppTests.swift` changes (already in test target).

- [ ] **Step 9: Run streak tests**

```bash
xcodebuild test \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:LastAppTests/HabitStreakTests \
  2>&1 | grep -E "(PASS|FAIL|error:)" | head -20
```

Expected: All 6 streak tests PASS.

- [ ] **Step 10: Commit**

```bash
git add LastApp/Features LastApp/Shared/Models LastAppTests/
git commit -m "Add SwiftData models: TaskItem, TaskList, Habit, HabitLog, FeatureConfig, FeatureLink"
```

---

## Task 3: App state, navigation types, and feature system

**Files:**
- Create: `LastApp/Core/Features/FeatureKey.swift`
- Create: `LastApp/Core/Features/FeatureDefinition.swift`
- Create: `LastApp/Core/Features/FeatureRegistry.swift`
- Create: `LastApp/Core/Navigation/SidebarDestination.swift`
- Create: `LastApp/Core/AppState.swift`

- [ ] **Step 1: Write `FeatureKey.swift`**

```swift
// LastApp/Core/Features/FeatureKey.swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
}
```

- [ ] **Step 2: Write `SidebarDestination.swift`**

```swift
// LastApp/Core/Navigation/SidebarDestination.swift
import Foundation

enum SidebarDestination: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case list(UUID)   // custom TaskList by its id
    case habits
    case settings
}
```

- [ ] **Step 3: Write `AppState.swift`**

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

- [ ] **Step 4: Write `FeatureDefinition.swift`**

```swift
// LastApp/Core/Features/FeatureDefinition.swift
import SwiftUI

struct FeatureDefinition {
    let key: FeatureKey
    let displayName: String
    let icon: String           // SF Symbol name
    let isAlwaysOn: Bool       // if true, cannot be toggled off in Settings

    /// Builds the sidebar row for this feature.
    let makeSidebarRow: (_ isSelected: Bool, _ onSelect: @escaping () -> Void) -> AnyView

    /// Builds the root content view for this feature.
    let makeRootView: (_ appState: AppState) -> AnyView
}
```

- [ ] **Step 5: Write `FeatureRegistry.swift`**

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

- [ ] **Step 6: Add files to Xcode project**

In Xcode, right-click the top-level `LastApp` group → "Add Files to LastApp..." → select the entire `LastApp/Core/` folder → "Create groups" → Add.

- [ ] **Step 7: Build to verify compilation**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add LastApp/Core/
git commit -m "Add AppState, SidebarDestination, FeatureKey, FeatureDefinition, FeatureRegistry"
```

---

## Task 4: App entry point and ModelContainer

**Files:**
- Modify: `LastApp/LastAppApp.swift` (replace generated)
- Modify: `LastApp/ContentView.swift` (replace with stub)

> Note: These files are already in the Xcode project. Just overwrite them on disk — no Xcode "add files" step needed.

- [ ] **Step 1: Replace `LastAppApp.swift`**

```swift
// LastApp/LastAppApp.swift
import SwiftUI
import SwiftData

@main
struct LastAppApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
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
        registerFeatures()
    }

    private func registerFeatures() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
    }
}
```

> `TasksFeature` and `HabitsFeature` are defined in Task 10. The app won't compile until then. This is expected — we'll fix it in Task 10 or use a stub (see Step 2).

- [ ] **Step 2: Add compile stubs for TasksFeature and HabitsFeature**

Create `LastApp/Features/Tasks/TasksFeature.swift`:

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

Create `LastApp/Features/Habits/HabitsFeature.swift`:

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

- [ ] **Step 3: Replace `ContentView.swift` with a stub**

```swift
// LastApp/ContentView.swift
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

- [ ] **Step 4: Add new stub files to Xcode project**

In Xcode, add to their respective groups:
- `LastApp/Features/Tasks/TasksFeature.swift`
- `LastApp/Features/Habits/HabitsFeature.swift`

- [ ] **Step 5: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add LastApp/LastAppApp.swift LastApp/ContentView.swift LastApp/Features/Tasks/TasksFeature.swift LastApp/Features/Habits/HabitsFeature.swift
git commit -m "Wire app entry point, ModelContainer, feature registration stubs"
```

---

## Task 5: Sidebar view and ContentView drawer

> **REQUIRED:** Invoke `frontend-design` skill before writing any view code in this task.

**Files:**
- Create: `LastApp/Core/Navigation/SidebarView.swift`
- Modify: `LastApp/ContentView.swift` (replace stub with full drawer implementation)

- [ ] **Step 1: Invoke `frontend-design` skill**

Before writing any view code, invoke the `frontend-design` skill. Design context:
- App: LastApp, a personal productivity app replacing TickTick et al.
- Tone: Calm, focused, personal — not corporate SaaS
- Accent: Teal `#14b8a6`; appearance: adaptive (system dark/light)
- This view: the sidebar drawer. Purpose: navigate between smart lists, custom lists, and feature modules. Slides in from left over content, dimmed backdrop.
- Reference: TickTick's iPhone sidebar aesthetic. Clean, readable, no decorative clutter.
- Typography: SF Rounded for section headers, SF default for list rows
- Avoid: gradients, heavy shadows, icon overload

- [ ] **Step 2: Write `SidebarView.swift`**

`SidebarView` receives the lists and enabled features via `@Query` from its parent or passed in. To keep it testable and composable, it takes explicit parameters:

```swift
// LastApp/Core/Navigation/SidebarView.swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
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
                        sectionDivider("LISTS")
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
            sidebarRow(
                icon: "tray",
                label: "Inbox",
                destination: .inbox
            )
            sidebarRow(
                icon: "sun.max",
                label: "Today",
                destination: .today
            )
            sidebarRow(
                icon: "calendar",
                label: "Upcoming",
                destination: .upcoming
            )
            sidebarRow(
                icon: "checkmark.circle",
                label: "Completed",
                destination: .completed
            )
        }
    }

    private var customListsSection: some View {
        ForEach(customLists) { list in
            sidebarRow(
                icon: list.icon,
                label: list.name,
                destination: .list(list.id)
            )
        }
    }

    private var enabledFeaturesSection: some View {
        ForEach(enabledFeatures, id: \.id) { config in
            if let feature = FeatureRegistry.definition(for: config.featureKey),
               !feature.isAlwaysOn {
                sectionDivider(feature.displayName.uppercased())
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

    private func sectionDivider(_ title: String) -> some View {
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

- [ ] **Step 3: Replace `ContentView.swift` with full drawer implementation**

```swift
// LastApp/ContentView.swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        ZStack(alignment: .leading) {
            // Main content
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Dim overlay when sidebar is open
            if appState.isSidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { appState.isSidebarOpen = false }
                    .transition(.opacity)
            }

            // Sidebar drawer
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
        case .inbox, .today, .upcoming, .completed, .list:
            TaskListView()
        case .habits:
            HabitListView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, TaskList.self, Habit.self, HabitLog.self, FeatureConfig.self, FeatureLink.self], inMemory: true)
}
```

Note: `TaskListView`, `HabitListView`, and `SettingsView` are stubs until later tasks.

- [ ] **Step 4: Add `SidebarView.swift` to Xcode project**

Right-click `Core/Navigation` group in Xcode → "Add Files to LastApp..." → select `SidebarView.swift` → Add.

- [ ] **Step 5: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

If errors appear about `TaskListView`, `HabitListView`, or `SettingsView` not found, add temporary stubs at the bottom of `ContentView.swift`:

```swift
// Temporary stubs — remove when actual views are implemented
struct TaskListView: View { var body: some View { Text("Tasks") } }
struct HabitListView: View { var body: some View { Text("Habits") } }
struct SettingsView: View { var body: some View { Text("Settings") } }
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add LastApp/Core/Navigation/SidebarView.swift LastApp/ContentView.swift
git commit -m "Add sidebar drawer and ContentView ZStack navigation"
```

---

## Task 6: Task ViewModel and TaskListView

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Tasks/ViewModels/TaskViewModel.swift`
- Create: `LastApp/Features/Tasks/Views/TaskListView.swift`
- Create: `LastApp/Features/Tasks/Views/TaskRowView.swift`

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context for this task:
- Views: `TaskListView` (main list screen) and `TaskRowView` (individual row)
- This is the heart of the app — users will stare at this all day
- List rows: completion circle (tap = done), title, priority dot (colored circle), due date chip (gray pill). Completed tasks: strikethrough, muted
- Quick-add FAB: teal circle with `+` in bottom-right corner
- NavigationTitle changes based on destination (Inbox, Today, Upcoming, etc.)
- Empty state: friendly, minimalist message
- Avoid: dense text, excessive borders, complex row layouts

- [ ] **Step 2: Write `TaskViewModel.swift`**

```swift
// LastApp/Features/Tasks/ViewModels/TaskViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class TaskViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addTask(title: String, notes: String = "", dueDate: Date? = nil, priority: Priority = .p4, list: TaskList? = nil) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, list: list)
        context.insert(task)
    }

    func complete(_ task: TaskItem) {
        task.isCompleted = true
        task.completedAt = Date()
    }

    func uncomplete(_ task: TaskItem) {
        task.isCompleted = false
        task.completedAt = nil
    }

    func toggleComplete(_ task: TaskItem) {
        if task.isCompleted { uncomplete(task) } else { complete(task) }
    }

    func delete(_ task: TaskItem) {
        context.delete(task)
    }

    func delete(_ tasks: [TaskItem]) {
        tasks.forEach { context.delete($0) }
    }

    func updateSortOrder(_ tasks: [TaskItem]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }
}
```

- [ ] **Step 3: Write `TaskRowView.swift`**

```swift
// LastApp/Features/Tasks/Views/TaskRowView.swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Completion circle
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.appAccent : Color.priorityColor(task.priority),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.appAccent)
                    }
                }
            }
            .buttonStyle(.plain)

            // Title + metadata
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(.body))
                    .foregroundStyle(task.isCompleted ? .tertiary : .primary)
                    .strikethrough(task.isCompleted, color: .tertiary)
                    .lineLimit(2)

                if let due = task.dueDate, !task.isCompleted {
                    Text(due.shortFormatted)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(due < Date() ? .red : .secondary)
                }
            }

            Spacer()

            // Priority dot (only for non-default priority)
            if task.priority != .p4 {
                Circle()
                    .fill(Color.priorityColor(task.priority))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
```

- [ ] **Step 4: Write `TaskListView.swift`**

```swift
// LastApp/Features/Tasks/Views/TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @State private var showingCreation = false
    private lazy var viewModel = TaskViewModel(context: modelContext)

    init() {
        // Default query; predicate set dynamically via task filtering
        _allTasks = Query(sort: \TaskItem.sortOrder)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }

            // FAB
            Button {
                showingCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(.title2, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.appAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(AppTheme.padding)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreation) {
            TaskCreationView()
        }
    }

    // MARK: - Subviews

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(value: task) {
                    TaskRowView(task: task) {
                        withAnimation { viewModel.toggleComplete(task) }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                viewModel.delete(offsets.map { filteredTasks[$0] })
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(emptyStateMessage)
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtering

    private var filteredTasks: [TaskItem] {
        let now = Date()
        switch appState.selectedDestination {
        case .inbox:
            return allTasks.filter { $0.list == nil && !$0.isCompleted }
        case .today:
            return allTasks.filter {
                !$0.isCompleted &&
                $0.dueDate.map { $0 <= now.endOfDay } ?? false
            }
        case .upcoming:
            return allTasks.filter {
                !$0.isCompleted &&
                $0.dueDate.map { $0 > now.endOfDay } ?? false
            }
        case .completed:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return allTasks.filter {
                $0.isCompleted &&
                ($0.completedAt ?? $0.dueDate ?? Date.distantPast) >= thirtyDaysAgo
            }
        case .list(let id):
            return allTasks.filter { $0.list?.id == id && !$0.isCompleted }
        case .habits, .settings:
            return []
        }
    }

    private var navigationTitle: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .list(let id):
            // Find the list name — fall back to "List"
            allTasks.first { $0.list?.id == id }?.list?.name ?? "List"
        case .habits, .settings: ""
        }
    }

    private var emptyStateIcon: String {
        switch appState.selectedDestination {
        case .inbox: "tray"
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .completed: "checkmark.circle"
        default: "list.bullet"
        }
    }

    private var emptyStateMessage: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox zero"
        case .today: "Nothing due today"
        case .upcoming: "Nothing coming up"
        case .completed: "No completed tasks"
        default: "No tasks"
        }
    }
}
```

Note: `TaskCreationView` and `TaskDetailView` are stubs until Task 7 and 8.

- [ ] **Step 5: Add files to Xcode project**

Right-click `Features/Tasks/ViewModels` and `Features/Tasks/Views` groups in Xcode → add each new file.

- [ ] **Step 6: Remove ContentView stubs if present**

If Task 5 added `struct TaskListView` as a stub at the bottom of `ContentView.swift`, remove those lines now.

- [ ] **Step 7: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

If `TaskCreationView` or `TaskDetailView` are missing, add stubs to `TaskListView.swift` temporarily:

```swift
// Stubs — remove when Tasks 7 and 8 are complete
struct TaskCreationView: View { var body: some View { Text("Create Task") } }
struct TaskDetailView: View { let task: TaskItem; var body: some View { Text(task.title) } }
```

- [ ] **Step 8: Commit**

```bash
git add LastApp/Features/Tasks/ViewModels LastApp/Features/Tasks/Views
git commit -m "Add TaskViewModel, TaskListView, TaskRowView"
```

---

## Task 7: Task creation sheet

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Tasks/Views/TaskCreationView.swift`

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- Sheet that slides up from the bottom. Starts in quick-add mode.
- Quick mode: large title text field (cursor auto-focused), row of shortcut buttons (Today / Tomorrow / Next Week), priority selector (P1–P4 colored circles), Done button. Expand chevron (↑) to reveal full detail.
- Full mode: adds Notes field, List picker, Tags field.
- Keyboard should be immediately active on present.
- Teal Done button. Dismiss on empty title tap (don't save).
- Avoid: modal titlebars, excessive fields upfront, any onboarding copy.

- [ ] **Step 2: Write `TaskCreationView.swift`**

```swift
// LastApp/Features/Tasks/Views/TaskCreationView.swift
import SwiftUI
import SwiftData

struct TaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date? = nil
    @State private var priority: Priority = .p4
    @State private var selectedList: TaskList? = nil
    @State private var isExpanded = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Title input
                TextField("Task name", text: $title, axis: .vertical)
                    .font(.system(.title3, weight: .medium))
                    .focused($titleFocused)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .onSubmit { saveIfValid() }

                Divider()

                // Quick action bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        dateChip("Today", date: Date())
                        dateChip("Tomorrow", date: .tomorrow)
                        dateChip("Next Week", date: .nextWeek)

                        Divider().frame(height: 20)

                        ForEach(Priority.allCases, id: \.self) { p in
                            priorityChip(p)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.vertical, 10)
                }

                if isExpanded {
                    Divider()
                    expandedFields
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { saveIfValid() }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(title.isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { saveIfValid() }
                }
            }
        }
        .presentationDetents(isExpanded ? [.large] : [.height(260)])
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
    }

    // MARK: - Expanded fields

    private var expandedFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Notes", text: $notes, axis: .vertical)
                .font(.system(.body))
                .foregroundStyle(.secondary)
                .padding(AppTheme.padding)

            Divider()

            // List picker
            if !customLists.isEmpty {
                Picker("List", selection: $selectedList) {
                    Text("Inbox").tag(nil as TaskList?)
                    ForEach(customLists) { list in
                        Label(list.name, systemImage: list.icon).tag(list as TaskList?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)
                Divider()
            }
        }
    }

    // MARK: - Chip builders

    private func dateChip(_ label: String, date: Date) -> some View {
        let isSelected = dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            dueDate = isSelected ? nil : date
        } label: {
            Text(label)
                .font(.system(.caption, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.appAccent : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func priorityChip(_ p: Priority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = isSelected ? .p4 : p
        } label: {
            Circle()
                .fill(Color.priorityColor(p))
                .frame(width: 28, height: 28)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(.white, lineWidth: 2.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func saveIfValid() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { dismiss(); return }
        let task = TaskItem(title: trimmed, notes: notes, dueDate: dueDate, priority: priority, list: selectedList)
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    TaskCreationView()
        .modelContainer(for: [TaskItem.self, TaskList.self], inMemory: true)
}
```

- [ ] **Step 3: Remove any TaskCreationView stub in TaskListView.swift**

If Task 6 added a `struct TaskCreationView` stub, remove it.

- [ ] **Step 4: Add file to Xcode project**

In Xcode, add `TaskCreationView.swift` to the `Features/Tasks/Views` group.

- [ ] **Step 5: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add LastApp/Features/Tasks/Views/TaskCreationView.swift
git commit -m "Add TaskCreationView quick-add sheet with expand toggle"
```

---

## Task 8: Task detail view

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Tasks/Views/TaskDetailView.swift`

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- Full screen pushed from task row tap
- Inline editing: title at the top (large, editable), then notes, due date picker, priority selector, tags, list picker, subtasks
- Subtasks: displayed as a nested list with their own completion circles; add subtask inline
- Feel: document-like — clean, spacious, no excessive chrome
- Navigation back button is the standard iOS back chevron
- Mark complete button: prominent teal button at the bottom or in the toolbar
- Avoid: tab bars inside the view, excessive section headers, modal-within-modal patterns

- [ ] **Step 2: Write `TaskDetailView.swift`**

```swift
// LastApp/Features/Tasks/Views/TaskDetailView.swift
import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]

    @State private var newSubtaskTitle = ""
    @State private var showingDatePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                Divider().padding(.vertical, 4)
                notesSection
                Divider().padding(.vertical, 4)
                metadataSection
                Divider().padding(.vertical, 4)
                subtasksSection
            }
            .padding(.vertical, AppTheme.padding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation { task.isCompleted.toggle()
                        if task.isCompleted { task.completedAt = Date() }
                        else { task.completedAt = nil }
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.isCompleted ? Color.appAccent : .secondary)
                        .font(.system(.title3))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        TextField("Task title", text: $task.title, axis: .vertical)
            .font(.system(.title2, weight: .semibold))
            .padding(.horizontal, AppTheme.padding)
            .padding(.bottom, 8)
    }

    private var notesSection: some View {
        TextField("Notes", text: $task.notes, axis: .vertical)
            .font(.system(.body))
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            // Due date
            HStack {
                Label(
                    task.dueDate.map { $0.shortFormatted } ?? "No date",
                    systemImage: "calendar"
                )
                .foregroundStyle(task.dueDate == nil ? .secondary : .primary)
                Spacer()
                if task.dueDate != nil {
                    Button("Clear") { task.dueDate = nil }
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { showingDatePicker.toggle() }

            if showingDatePicker {
                DatePicker("Due date", selection: Binding(
                    get: { task.dueDate ?? Date() },
                    set: { task.dueDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.appAccent)
                .padding(.horizontal, AppTheme.padding)
            }

            Divider().padding(.vertical, 4)

            // Priority
            HStack(spacing: 8) {
                Label("Priority", systemImage: "flag")
                    .foregroundStyle(.secondary)
                    .font(.system(.body))
                Spacer()
                ForEach(Priority.allCases, id: \.self) { p in
                    Button {
                        task.priority = task.priority == p ? .p4 : p
                    } label: {
                        Circle()
                            .fill(Color.priorityColor(p))
                            .frame(width: 24, height: 24)
                            .overlay {
                                if task.priority == p {
                                    Circle().strokeBorder(.white, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)

            Divider().padding(.vertical, 4)

            // List picker
            Picker("List", selection: $task.list) {
                Label("Inbox", systemImage: "tray").tag(nil as TaskList?)
                ForEach(customLists) { list in
                    Label(list.name, systemImage: list.icon).tag(list as TaskList?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 8)
        }
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Subtasks")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppTheme.padding)
                .padding(.top, 12)

            ForEach(task.subtasks) { subtask in
                HStack(spacing: 12) {
                    Button {
                        subtask.isCompleted.toggle()
                    } label: {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(subtask.isCompleted ? Color.appAccent : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .strikethrough(subtask.isCompleted, color: .tertiary)
                        .foregroundStyle(subtask.isCompleted ? .tertiary : .primary)
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 8)
            }

            // Add subtask field
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.appAccent)
                TextField("Add subtask", text: $newSubtaskTitle)
                    .font(.system(.body))
                    .onSubmit { addSubtask() }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let subtask = TaskItem(title: trimmed)
        modelContext.insert(subtask)
        task.subtasks.append(subtask)
        newSubtaskTitle = ""
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskItem.self, TaskList.self, configurations: config)
    let task = TaskItem(title: "Sample task", notes: "Some notes", priority: .p2)
    container.mainContext.insert(task)
    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Remove TaskDetailView stub if present**

Remove any `struct TaskDetailView` stub from `TaskListView.swift`.

- [ ] **Step 4: Add file to Xcode project**

In Xcode, add `TaskDetailView.swift` to the `Features/Tasks/Views` group.

- [ ] **Step 5: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add LastApp/Features/Tasks/Views/TaskDetailView.swift
git commit -m "Add TaskDetailView with inline editing, priority, subtasks"
```

---

## Task 9: Habit ViewModel and HabitListView

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Habits/ViewModels/HabitViewModel.swift`
- Create: `LastApp/Features/Habits/Views/HabitListView.swift`
- Create: `LastApp/Features/Habits/Views/HabitRowView.swift`

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- HabitListView: list of habits. Each row = habit name, streak flame + count, frequency badge, completion circle for today
- Completed habits: circle fills with teal, row gets lighter opacity
- Streak: small flame emoji + number, shown in muted teal color
- FAB: same pattern as TaskListView — teal `+` bottom-right
- Empty state: motivating, not generic ("Start your first habit")
- Design tone: calm momentum — streaks feel like progress, not pressure
- HabitRowView should feel lighter/warmer than TaskRowView — habits are routine, not urgent

- [ ] **Step 2: Write `HabitViewModel.swift`**

```swift
// LastApp/Features/Habits/ViewModels/HabitViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class HabitViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addHabit(name: String, frequency: Frequency) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(name: name, frequency: frequency)
        context.insert(habit)
    }

    func toggleToday(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = habit.logs.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isCompleted.toggle()
        } else {
            let log = HabitLog(date: Date(), isCompleted: true, habit: habit)
            context.insert(log)
        }
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
    }
}
```

- [ ] **Step 3: Write `HabitRowView.swift`**

```swift
// LastApp/Features/Habits/Views/HabitRowView.swift
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Completion circle
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? Color.appAccent : Color.clear)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(
                            habit.isCompletedToday ? Color.appAccent : Color.secondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 28, height: 28)
                    if habit.isCompletedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(.body))
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                Text(habit.frequency.rawValue)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Streak
            if habit.streak > 0 {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(.caption))
                    Text("\(habit.streak)")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
```

- [ ] **Step 4: Write `HabitListView.swift`**

```swift
// LastApp/Features/Habits/Views/HabitListView.swift
import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingCreation = false
    private lazy var viewModel = HabitViewModel(context: modelContext)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }

            Button {
                showingCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(.title2, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.appAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(AppTheme.padding)
        }
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreation) {
            HabitCreationView()
        }
    }

    private var habitList: some View {
        List {
            ForEach(habits) { habit in
                NavigationLink(value: habit) {
                    HabitRowView(habit: habit) {
                        withAnimation { viewModel.toggleToday(habit) }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                offsets.map { habits[$0] }.forEach { viewModel.delete($0) }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Habit.self) { habit in
            HabitDetailView(habit: habit)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 48))
            Text("Start your first habit")
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 5: Remove HabitListView stub if present**

If `ContentView.swift` had a `struct HabitListView` stub, remove it.

- [ ] **Step 6: Add files to Xcode project**

In Xcode, add to their groups:
- `LastApp/Features/Habits/ViewModels/HabitViewModel.swift`
- `LastApp/Features/Habits/Views/HabitListView.swift`
- `LastApp/Features/Habits/Views/HabitRowView.swift`

- [ ] **Step 7: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

If `HabitCreationView` or `HabitDetailView` not found, add stubs at the bottom of `HabitListView.swift`:

```swift
struct HabitCreationView: View { var body: some View { Text("Create Habit") } }
struct HabitDetailView: View { let habit: Habit; var body: some View { Text(habit.name) } }
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add LastApp/Features/Habits/ViewModels LastApp/Features/Habits/Views/HabitListView.swift LastApp/Features/Habits/Views/HabitRowView.swift
git commit -m "Add HabitViewModel, HabitListView, HabitRowView"
```

---

## Task 10: Habit creation and detail views

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Habits/Views/HabitCreationView.swift`
- Create: `LastApp/Features/Habits/Views/HabitDetailView.swift`

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- HabitCreationView: minimal sheet — just name + frequency picker. Done button. Auto-focus on name field.
- HabitDetailView: shows habit name (editable), frequency picker, creation date, and a 30-day calendar grid. Grid: small circles, filled teal = completed, empty = missed. Label rows with day abbreviations.
- Calendar grid: 5 columns × 6 rows showing last 30 days, right-aligned so today is in the last position
- Avoid: excessive stats, progress bars with percentages, gamification UI

- [ ] **Step 2: Write `HabitCreationView.swift`**

```swift
// LastApp/Features/Habits/Views/HabitCreationView.swift
import SwiftUI

struct HabitCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var frequency: Frequency = .daily
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit name", text: $name)
                        .focused($nameFocused)
                        .font(.system(.body))
                }

                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(name.isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { nameFocused = true }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let habit = Habit(name: trimmed, frequency: frequency)
        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    HabitCreationView()
        .modelContainer(for: Habit.self, inMemory: true)
}
```

- [ ] **Step 3: Write `HabitDetailView.swift`**

```swift
// LastApp/Features/Habits/Views/HabitDetailView.swift
import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private var last30Days: [Date] {
        (0..<30).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -(29 - offset), to: Calendar.current.startOfDay(for: .now))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Name
                TextField("Habit name", text: $habit.name)
                    .font(.system(.title2, weight: .semibold))
                    .padding(.horizontal, AppTheme.padding)

                // Frequency
                Picker("Frequency", selection: Binding(
                    get: { habit.frequency },
                    set: { habit.frequencyRaw = $0.rawValue }
                )) {
                    ForEach(Frequency.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.padding)

                // Stats row
                HStack(spacing: 24) {
                    statPill(label: "Streak", value: "\(habit.streak) \(habit.streak == 1 ? "day" : "days")")
                    statPill(label: "Started", value: habit.createdAt.shortFormatted)
                }
                .padding(.horizontal, AppTheme.padding)

                // 30-day grid
                calendarGrid
            }
            .padding(.vertical, AppTheme.padding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(habit)
                        dismiss()
                    } label: {
                        Label("Delete Habit", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 30 days")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppTheme.padding)

            // Day abbreviation header
            HStack(spacing: 6) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.quaternary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.padding)

            LazyVGrid(columns: gridColumns, spacing: 6) {
                // Fill leading empty cells to align first day
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Circle().fill(Color.clear).frame(width: 28, height: 28)
                }
                ForEach(last30Days, id: \.self) { day in
                    let completed = isCompleted(day)
                    Circle()
                        .fill(completed ? Color.appAccent : Color.secondary.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day.isToday {
                                Circle().strokeBorder(Color.appAccent.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                }
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    private var leadingEmptyCells: Int {
        guard let first = last30Days.first else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: first) // 1=Sun
        return weekday - 1
    }

    private func isCompleted(_ date: Date) -> Bool {
        habit.logs.contains {
            $0.isCompleted && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(.subheadline, weight: .semibold))
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    let habit = Habit(name: "Read daily", frequency: .daily)
    container.mainContext.insert(habit)
    return NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(container)
}
```

- [ ] **Step 4: Remove habit view stubs if present**

Remove any `HabitCreationView` or `HabitDetailView` stubs from `HabitListView.swift`.

- [ ] **Step 5: Add files to Xcode project**

In Xcode, add to `Features/Habits/Views`:
- `HabitCreationView.swift`
- `HabitDetailView.swift`

- [ ] **Step 6: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add LastApp/Features/Habits/Views/HabitCreationView.swift LastApp/Features/Habits/Views/HabitDetailView.swift
git commit -m "Add HabitCreationView and HabitDetailView with 30-day calendar grid"
```

---

## Task 11: Today view (combined tasks + habits)

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Features/Tasks/Views/TodayView.swift`
- Modify: `LastApp/ContentView.swift` (route `.today` to `TodayView`)

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- Combined view: habits section at top, task list below
- Header for each section: "HABITS" and "TASKS" in small caps, same style as sidebar section headers
- Habits section: compact row of habit check-circles — not the full HabitRowView; just name + circle (like a widget row). Hidden if no habits.
- Tasks section: same TaskRowView as everywhere else
- If habits section is empty (no habits configured), skip it entirely — don't show the section header
- NavigationTitle: "Today" with the current date as subtitle
- Tone: morning dashboard feel — calm overview, not overwhelming

- [ ] **Step 2: Write `TodayView.swift`**

```swift
// LastApp/Features/Tasks/Views/TodayView.swift
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingTaskCreation = false
    private lazy var taskVM = TaskViewModel(context: modelContext)
    private lazy var habitVM = HabitViewModel(context: modelContext)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    if !habits.isEmpty {
                        habitsSection
                    }
                    tasksSection
                }
            }

            Button {
                showingTaskCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(.title2, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.appAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(AppTheme.padding)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingTaskCreation) {
            TaskCreationView()
        }
    }

    // MARK: - Habits section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("HABITS")

            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Button {
                        withAnimation { habitVM.toggleToday(habit) }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(habit.isCompletedToday ? Color.appAccent : Color.clear)
                                .frame(width: 24, height: 24)
                            Circle()
                                .strokeBorder(
                                    habit.isCompletedToday ? Color.appAccent : Color.secondary.opacity(0.4),
                                    lineWidth: 1.5
                                )
                                .frame(width: 24, height: 24)
                            if habit.isCompletedToday {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text(habit.name)
                        .font(.system(.body))
                        .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                    Spacer()

                    if habit.streak > 0 {
                        Text("🔥 \(habit.streak)")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)

                Divider().padding(.leading, AppTheme.padding + 24 + 12)
            }
        }
    }

    // MARK: - Tasks section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("TASKS")

            if todayTasks.isEmpty {
                HStack {
                    Spacer()
                    Text("Nothing due today")
                        .font(.system(.subheadline))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(todayTasks) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task) {
                            withAnimation { taskVM.toggleComplete(task) }
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, AppTheme.padding + 22 + 14)
                }
                .navigationDestination(for: TaskItem.self) { task in
                    TaskDetailView(task: task)
                }
            }
        }
    }

    // MARK: - Helpers

    private var todayTasks: [TaskItem] {
        let endOfToday = Date().endOfDay
        return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 <= endOfToday } ?? false) }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environment(AppState())
    .modelContainer(for: [TaskItem.self, Habit.self, HabitLog.self], inMemory: true)
}
```

- [ ] **Step 3: Update `ContentView.swift` to route `.today` to `TodayView`**

In `ContentView.swift`, find `destinationView` and update the `.today` case:

```swift
@ViewBuilder
private var destinationView: some View {
    switch appState.selectedDestination {
    case .today:
        TodayView()
    case .inbox, .upcoming, .completed, .list:
        TaskListView()
    case .habits:
        HabitListView()
    case .settings:
        SettingsView()
    }
}
```

- [ ] **Step 4: Add `TodayView.swift` to Xcode project**

Right-click `Features/Tasks/Views` → "Add Files to LastApp..." → add `TodayView.swift`.

- [ ] **Step 5: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add LastApp/Features/Tasks/Views/TodayView.swift LastApp/ContentView.swift
git commit -m "Add TodayView with combined habits and tasks sections"
```

---

## Task 12: Settings, feature toggle, and feature wiring

> **REQUIRED:** Invoke `frontend-design` skill before writing view code.

**Files:**
- Create: `LastApp/Core/Settings/SettingsView.swift`
- Create: `LastApp/Core/Settings/FeatureToggleView.swift`
- Modify: `LastApp/Features/Tasks/TasksFeature.swift` (replace stub with real implementation)
- Modify: `LastApp/Features/Habits/HabitsFeature.swift` (replace stub with real implementation)
- Modify: `LastApp/LastAppApp.swift` (add FeatureConfig seed on first launch)

- [ ] **Step 1: Invoke `frontend-design` skill**

Design context:
- SettingsView: simple list with a "Features" section showing toggleable modules
- FeatureToggleView: one row per feature — icon, name, toggle. Always-on features (Tasks) show a toggle disabled/locked.
- Secondary sections: About, version number
- Tone: plain, functional — not a feature showcase
- Navigation: pushed from sidebar "Settings" row

- [ ] **Step 2: Write `FeatureToggleView.swift`**

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

- [ ] **Step 3: Write `SettingsView.swift`**

```swift
// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]
    @Environment(\.modelContext) private var modelContext

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

- [ ] **Step 4: Update `TasksFeature.swift` with real implementation**

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
        makeRootView: { appState in
            AnyView(TaskListView())
        }
    )
}
```

- [ ] **Step 5: Update `HabitsFeature.swift` with real implementation**

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

- [ ] **Step 6: Seed FeatureConfig on first launch in `LastAppApp.swift`**

Add a seed method and call it from `.onAppear` on the first `WindowGroup` scene:

```swift
// LastApp/LastAppApp.swift
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
        registerFeatures()
    }

    private func registerFeatures() {
        FeatureRegistry.register(TasksFeature.definition)
        FeatureRegistry.register(HabitsFeature.definition)
    }

    @MainActor
    private func seedFeaturesIfNeeded() async {
        // Access the shared model container to seed data
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

Note: The seed function uses a separate `ModelContainer` instance to avoid accessing the main container before it's ready. In practice, a cleaner approach uses the `@Environment(\.modelContext)` in the root view. If this causes issues, move the seed call into `ContentView.onAppear` via the environment's `modelContext`.

- [ ] **Step 7: Remove SettingsView stub if present**

Remove any `struct SettingsView` stub from `ContentView.swift`.

- [ ] **Step 8: Add files to Xcode project**

In Xcode, add to `Core/Settings`:
- `SettingsView.swift`
- `FeatureToggleView.swift`

- [ ] **Step 9: Build**

```bash
xcodebuild \
  -scheme LastApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: Run all tests**

```bash
xcodebuild test \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)" | head -30
```

Expected: All tests in `PriorityTests`, `DateHelperTests`, `HabitStreakTests` pass.

- [ ] **Step 11: Commit**

```bash
git add LastApp/Core/Settings LastApp/Features/Tasks/TasksFeature.swift LastApp/Features/Habits/HabitsFeature.swift LastApp/LastAppApp.swift
git commit -m "Add Settings, FeatureToggleView, wire TasksFeature and HabitsFeature, seed FeatureConfig"
```

---

## Self-Review

### Spec Coverage Check

| Spec requirement | Task |
|---|---|
| Task/to-do lists with inbox, custom lists, smart lists | Task 6 (TaskListView + filtering) |
| Task creation: title, notes, due date, priority, tags, subtasks | Task 7 (TaskCreationView) + Task 8 (TaskDetailView) |
| Drag-to-reorder | Task 6 (`.onMove` on ForEach) — **gap: `.onMove` not implemented** |
| Quick-add | Task 7 (TaskCreationView quick mode) |
| Habit tracker: daily/weekly, streaks, check-off | Tasks 9–10 |
| Modular feature enable/disable | Task 12 (SettingsView + FeatureConfig) |
| Features in sidebar | Task 5 (SidebarView reads FeatureConfig) |
| Cross-referencing (FeatureLink) | Model defined, not actively used — per spec, this is correct for MVP |
| Sidebar drawer navigation | Task 5 (ContentView + SidebarView) |
| Adaptive appearance | Native SwiftUI — no explicit code needed; system handles it |
| Teal accent | Task 1 (AppTheme) |

**Gap found: Drag-to-reorder** — `TaskListView` calls `viewModel.updateSortOrder` but the `List` doesn't have `.onMove` enabled. Add this to Task 6's `taskList` computed property:

```swift
.onMove { from, to in
    var reordered = filteredTasks
    reordered.move(fromOffsets: from, toOffset: to)
    viewModel.updateSortOrder(reordered)
}
```

This should be added to the `ForEach` in `TaskListView.taskList` during Task 6 execution.

### Placeholder Scan

No TBDs, TODOs, or vague steps found.

### Type Consistency

- `Priority` used as `task.priority` (computed var from `priorityRaw: Int`) — consistent across TaskItem, TaskCreationView, TaskDetailView, TaskRowView ✓
- `Frequency` used as `habit.frequency` (computed var from `frequencyRaw: String`) — consistent across Habit, HabitCreationView, HabitDetailView ✓
- `SidebarDestination.list(UUID)` — used in SidebarView and matched in TaskListView/ContentView ✓
- `FeatureConfig.featureKey` (computed from `featureKeyRaw: String`) — used consistently in SettingsView and SidebarView ✓
- `AppTheme.sidebarWidth` defined in Task 1, used in SidebarView Task 5 ✓
- `TaskViewModel` initialized with `modelContext` — used in TaskListView and TodayView ✓
- `HabitViewModel` initialized with `modelContext` — used in HabitListView and TodayView ✓

All type references are internally consistent.
