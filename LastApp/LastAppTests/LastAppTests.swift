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

// MARK: - Habit Streak Tests

import SwiftData

@MainActor
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
