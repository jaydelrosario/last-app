// LastApp/Features/Habits/Views/HabitRowView.swift
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? Color.appAccent : Color.clear)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(
                            habit.isCompletedToday ? Color.appAccent : Color.secondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 28, height: 28)
                    if habit.isCompletedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.displayName)
                    .font(.system(.body))
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                Text(habit.scheduleText.isEmpty ? habit.frequency.rawValue : habit.scheduleText)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if habit.streak > 0 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(.caption))
                    Text("\(habit.streak)")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
