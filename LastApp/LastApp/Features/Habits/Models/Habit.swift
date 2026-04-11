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
