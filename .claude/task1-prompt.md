You are implementing Task 1 of the LastApp iOS project: Shared theme, enums, and date helpers.

## Your Job

1. Create directory structure
2. Write the Swift files
3. Add files to the Xcode project using the xcodeproj gem
4. Run tests with xcodebuild
5. Commit
6. Report back with status DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT

## Paths

- Git root: `/Users/jay/dev/last-app/`
- Source files: `/Users/jay/dev/last-app/LastApp/LastApp/` (nested LastApp — standard Xcode behavior)
- Tests: `/Users/jay/dev/last-app/LastApp/LastAppTests/`
- Xcode project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Step 1: Create directories

```bash
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Shared/Theme
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Shared/Extensions
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Shared/Models
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Models
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/ViewModels
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Models
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/ViewModels
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Core/Features
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Core/Navigation
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/Core/Settings
mkdir -p /Users/jay/dev/last-app/LastApp/LastApp/App
```

## Step 2: Write test file

Write to `/Users/jay/dev/last-app/LastApp/LastAppTests/LastAppTests.swift`:

```swift
import XCTest
@testable import LastApp

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

final class DateHelperTests: XCTestCase {
    func test_startOfDay_isAtMidnight() {
        let start = Date().startOfDay
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

## Step 3: Write Priority.swift

Write to `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Models/Priority.swift`:

```swift
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

## Step 4: Write Frequency.swift

Write to `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Models/Frequency.swift`:

```swift
import Foundation

enum Frequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
}
```

## Step 5: Write Date+Helpers.swift

Write to `/Users/jay/dev/last-app/LastApp/LastApp/Shared/Extensions/Date+Helpers.swift`:

```swift
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

## Step 6: Write AppTheme.swift

Write to `/Users/jay/dev/last-app/LastApp/LastApp/Shared/Theme/AppTheme.swift`:

```swift
import SwiftUI

extension Color {
    /// Teal accent: #14b8a6
    static let appAccent = Color(red: 0.082, green: 0.722, blue: 0.647)

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .p1: Color(red: 0.937, green: 0.267, blue: 0.267)
        case .p2: Color(red: 0.976, green: 0.451, blue: 0.086)
        case .p3: Color(red: 0.231, green: 0.510, blue: 0.965)
        case .p4: Color(red: 0.420, green: 0.447, blue: 0.502)
        }
    }
}

enum AppTheme {
    static let padding: CGFloat = 16
    static let rowSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 10
    static let sidebarWidth: CGFloat = 280
}
```

## Step 7: Add files to Xcode project

Install xcodeproj gem and run this script:

```bash
gem install xcodeproj 2>&1 | tail -2
```

Then run:

```bash
ruby -e "
require 'xcodeproj'

project = Xcodeproj::Project.open('/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj')
target = project.targets.find { |t| t.name == 'LastApp' }
main_group = project.main_group['LastApp']

def find_or_create_group(parent, parts)
  return parent if parts.empty?
  existing = parent.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == parts.first }
  group = existing || parent.new_group(parts.first)
  find_or_create_group(group, parts[1..])
end

files = [
  'LastApp/Shared/Theme/AppTheme.swift',
  'LastApp/Shared/Extensions/Date+Helpers.swift',
  'LastApp/Features/Tasks/Models/Priority.swift',
  'LastApp/Features/Habits/Models/Frequency.swift',
]

files.each do |rel|
  full = \"/Users/jay/dev/last-app/LastApp/#{rel}\"
  parts = rel.split('/')[1..-2]
  group = find_or_create_group(main_group, parts)
  ref = group.new_file(full)
  target.add_file_references([ref])
  puts \"Added: #{rel}\"
end

project.save
puts 'Done.'
"
```

## Step 8: Run tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:LastAppTests/PriorityTests \
  -only-testing:LastAppTests/DateHelperTests \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

Expected: 8 tests pass, BUILD SUCCEEDED.

## Step 9: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 1: Add theme, date helpers, Priority and Frequency enums with tests"
```

## Report back with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Test results
- Files changed
- Any concerns
