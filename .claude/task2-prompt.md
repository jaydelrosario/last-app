You are implementing Task 2 of the LastApp iOS project: SwiftData models.

## Context

LastApp is a native iOS SwiftUI + SwiftData productivity app. Task 1 is complete — Priority, Frequency, AppTheme, and Date+Helpers exist.

**Key facts:**
- Xcode 16 uses PBXFileSystemSynchronizedRootGroup — new Swift files on disk are auto-included, no xcodeproj manipulation needed
- Simulator: use 'iPhone 17 Pro' (only iOS 26.4 simulators available)
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Tests: `/Users/jay/dev/last-app/LastApp/LastAppTests/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Models/TaskItem.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Models/TaskList.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Models/HabitLog.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Models/Habit.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Shared/Models/FeatureConfig.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Shared/Models/FeatureLink.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastAppTests/LastAppTests.swift` — append habit streak tests

## Step 1: Append habit streak tests to LastAppTests.swift

Append to the end of `/Users/jay/dev/last-app/LastApp/LastAppTests/LastAppTests.swift`:

```swift
// MARK: - Habit Streak Tests

import SwiftData

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

## Step 2: Write TaskItem.swift

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

## Step 3: Write TaskList.swift

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

## Step 4: Write HabitLog.swift (before Habit.swift — Habit references HabitLog)

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

## Step 5: Write Habit.swift

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

## Step 6: Write FeatureConfig.swift

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

Note: `FeatureKey` is defined in Task 3. For now, add a temporary stub at the top of FeatureConfig.swift so it compiles:

```swift
// Temporary — will be replaced by Core/Features/FeatureKey.swift in Task 3
enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
}
```

Actually, since Task 3 will create the real FeatureKey, just define it inline in FeatureConfig.swift for now. Task 3 will move it to its own file; at that point the duplicate will cause a compile error and the inline one should be removed.

Better approach: create FeatureKey.swift now as part of this task to avoid the stub:

Create `/Users/jay/dev/last-app/LastApp/LastApp/Core/Features/FeatureKey.swift`:
```swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
}
```

Then FeatureConfig.swift just references FeatureKey without needing a stub.

## Step 7: Write FeatureLink.swift

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

## Step 8: Build to verify compilation

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

## Step 9: Run streak tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:LastAppTests/HabitStreakTests \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

Expected: 6 streak tests pass.

## Step 10: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

Expected: All 16 tests pass (10 from Task 1 + 6 new streak tests).

## Step 11: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 2: Add SwiftData models: TaskItem, TaskList, Habit, HabitLog, FeatureConfig, FeatureLink"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Test results
- Files changed
- Any concerns
