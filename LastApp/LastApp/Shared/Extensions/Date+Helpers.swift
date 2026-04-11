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
