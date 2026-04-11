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
