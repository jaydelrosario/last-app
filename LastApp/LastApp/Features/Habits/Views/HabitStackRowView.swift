// LastApp/Features/Habits/Views/HabitStackRowView.swift
import SwiftUI

struct HabitStackRowView: View {
    let stack: HabitStack
    let onEdit: () -> Void

    private var habits: [Habit] { stack.orderedHabits }

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 10) {
                // Chain of colored dots + arrows
                HStack(spacing: 6) {
                    ForEach(Array(habits.enumerated()), id: \.offset) { i, habit in
                        Circle()
                            .fill(habit.accentColor)
                            .frame(width: 14, height: 14)
                        if i < habits.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                // Habit names
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(habits.enumerated()), id: \.offset) { i, habit in
                        HStack(spacing: 6) {
                            Text(i == 0 ? "After" : "Then")
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .frame(width: 32, alignment: .leading)
                            Text(habit.displayName)
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
