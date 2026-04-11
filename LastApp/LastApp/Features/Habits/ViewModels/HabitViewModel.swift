// LastApp/Features/Habits/ViewModels/HabitViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class HabitViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addHabit(name: String, frequency: Frequency) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(name: name, frequency: frequency)
        context.insert(habit)
    }

    func toggleToday(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = habit.logs.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isCompleted.toggle()
        } else {
            let log = HabitLog(date: Date(), isCompleted: true, habit: habit)
            context.insert(log)
        }
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
    }
}
