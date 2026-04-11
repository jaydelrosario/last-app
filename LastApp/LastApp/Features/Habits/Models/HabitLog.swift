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
