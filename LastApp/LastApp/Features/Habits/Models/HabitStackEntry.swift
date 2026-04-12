// LastApp/Features/Habits/Models/HabitStackEntry.swift
import SwiftData
import Foundation

@Model
final class HabitStackEntry {
    var id: UUID = UUID()
    var sortOrder: Int = 0
    var stack: HabitStack?

    @Relationship(deleteRule: .nullify) var habit: Habit?

    init(sortOrder: Int, habit: Habit? = nil) {
        self.sortOrder = sortOrder
        self.habit = habit
    }
}
