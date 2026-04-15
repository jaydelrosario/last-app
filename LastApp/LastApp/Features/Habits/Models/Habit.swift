// LastApp/Features/Habits/Models/Habit.swift
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var frequencyRaw: String = Frequency.daily.rawValue
    var createdAt: Date = Date()

    // Atomic Habits fields
    var action: String = ""
    var identity: String = ""
    var scheduleDaysRaw: String = "0,1,2,3,4,5,6"   // 0=Sun … 6=Sat
    var goalCount: Int = 1
    var goalUnit: String = "time"
    var habitTimeInterval: Double = -1               // seconds from midnight; -1 = none
    var reminderEnabled: Bool = false
    var reminderOffsetMinutes: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit) var logs: [HabitLog] = []

    // MARK: - Computed

    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    var scheduleDays: [Int] {
        get { scheduleDaysRaw.split(separator: ",").compactMap { Int($0) }.sorted() }
        set { scheduleDaysRaw = newValue.sorted().map { String($0) }.joined(separator: ",") }
    }

    /// "every day at 9:00 PM", "on weekdays at 8:00 AM", etc.
    var scheduleText: String {
        let days = scheduleDays
        let timeStr = habitTimeInterval >= 0 ? " at \(formattedTime)" : ""
        if days.count == 7 { return "every day\(timeStr)" }
        if Set(days) == Set([1,2,3,4,5]) { return "on weekdays\(timeStr)" }
        if Set(days) == Set([0,6]) { return "on weekends\(timeStr)" }
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return "on \(days.map { names[$0] }.joined(separator: ", "))\(timeStr)"
    }

    var formattedTime: String {
        guard habitTimeInterval >= 0 else { return "" }
        let base = Calendar.current.startOfDay(for: .now).addingTimeInterval(habitTimeInterval)
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: base)
    }

    /// Display in list rows
    var displayName: String { action.isEmpty ? name : action }

    /// Deterministic accent color from id — used in habit stack dots
    var accentColor: Color {
        let palette: [Color] = [
            .orange,
            Color(red: 0.612, green: 0.196, blue: 0.898), // vivid purple
            Color(red: 0.239, green: 0.510, blue: 0.976), // bright blue
            Color(red: 0.459, green: 0.235, blue: 0.804), // indigo
            Color(red: 0.957, green: 0.416, blue: 0.631), // rose/pink
            Color(red: 0.961, green: 0.722, blue: 0.157), // warm amber
            Color(red: 0.118, green: 0.686, blue: 0.882), // sky blue
            Color(red: 0.431, green: 0.835, blue: 0.749), // aqua mint
            Color(red: 0.984, green: 0.502, blue: 0.251), // coral
            Color(red: 0.686, green: 0.478, blue: 0.992), // lavender
        ]
        let index = Int(id.uuidString.prefix(2), radix: 16) ?? 0
        return palette[index % palette.count]
    }

    // MARK: - Streak

    var streak: Int {
        let calendar = Calendar.current
        let completedDays = Set(
            logs.filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )
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
    }

    var isCompletedToday: Bool {
        isCompleted(on: .now)
    }

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return logs.contains {
            $0.isCompleted && Calendar.current.startOfDay(for: $0.date) == day
        }
    }

    init(name: String, frequency: Frequency = .daily) {
        self.name = name
        self.frequencyRaw = frequency.rawValue
        self.action = name
    }
}
