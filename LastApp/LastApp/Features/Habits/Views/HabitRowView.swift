// LastApp/Features/Habits/Views/HabitRowView.swift
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Left: colored rounded icon + streak count
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(habit.accentColor)
                        .frame(width: 52, height: 52)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                if habit.streak > 0 {
                    Text("\(habit.streak)")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(habit.accentColor)
                } else {
                    Text(" ")
                        .font(.system(.caption2))
                }
            }

            // Middle: name + schedule
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.displayName)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if !habit.scheduleText.isEmpty {
                    Text(habit.scheduleText)
                        .font(.system(.caption, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right: quick-log button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? habit.accentColor : Color.secondary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: habit.isCompletedToday ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(habit.isCompletedToday ? .white : Color.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
