// LastApp/Features/Habits/Views/HabitStackRowView.swift
import SwiftUI

struct HabitStackRowView: View {
    let stack: HabitStack
    var date: Date = .now
    let onEdit: () -> Void
    let onToggle: (Habit) -> Void

    private var habits: [Habit] { stack.orderedHabits }

    var body: some View {
        VStack(spacing: 0) {
            // Stack header
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("STACK")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "ellipsis")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Habit rows
            ForEach(Array(habits.enumerated()), id: \.element.id) { i, habit in
                VStack(spacing: 0) {
                    if i > 0 {
                        // Connector line between habits
                        HStack(spacing: 0) {
                            Spacer().frame(width: 16 + 26) // leading padding + half of icon width
                            Rectangle()
                                .fill(habit.accentColor.opacity(0.25))
                                .frame(width: 2, height: 10)
                            Spacer()
                        }
                    }

                    habitRow(habit: habit, isFirst: i == 0, isLast: i == habits.count - 1)
                }
            }
        }
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func habitRow(habit: Habit, isFirst: Bool, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            // Icon + streak
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.accentColor)
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                if habit.streak > 0 {
                    Text("\(habit.streak)")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(habit.accentColor.opacity(0.8), in: Capsule())
                        .offset(x: 6, y: 6)
                }
            }
            .padding(.bottom, habit.streak > 0 ? 6 : 0)

            // Name + sequence label
            VStack(alignment: .leading, spacing: 2) {
                Text(isFirst ? "Start with" : "Then")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.tertiary)
                Text(habit.displayName)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()

            // Completion button
            Button {
                onToggle(habit)
            } label: {
                ZStack {
                    Circle()
                        .fill(habit.isCompleted(on: date) ? habit.accentColor : Color.secondary.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: habit.isCompleted(on: date) ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(habit.isCompleted(on: date) ? .white : Color.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
