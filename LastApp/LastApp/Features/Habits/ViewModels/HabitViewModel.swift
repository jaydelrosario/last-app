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
        toggle(habit, for: .now)
    }

    func toggle(_ habit: Habit, for date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = habit.logs.first(where: {
            Calendar.current.startOfDay(for: $0.date) == day
        }) {
            existing.isCompleted.toggle()
        } else {
            let log = HabitLog(date: date, isCompleted: true, habit: habit)
            context.insert(log)
        }
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
    }
}
