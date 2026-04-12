// LastApp/Features/Habits/Models/HabitStack.swift
import SwiftData
import Foundation

@Model
final class HabitStack {
    var id: UUID = UUID()
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \HabitStackEntry.stack)
    var entries: [HabitStackEntry] = []

    var orderedEntries: [HabitStackEntry] {
        entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    var orderedHabits: [Habit] {
        orderedEntries.compactMap { $0.habit }
    }

    var cueHabit: Habit? { orderedHabits.first }

    /// "Read → Meditate → Journal"
    var displayName: String {
        orderedHabits.map { $0.displayName }.joined(separator: " → ")
    }

    init() {}
}
