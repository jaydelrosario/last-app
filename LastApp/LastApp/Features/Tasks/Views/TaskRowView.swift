// LastApp/Features/Tasks/Views/TaskRowView.swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.appAccent : Color.priorityColor(task.priority),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(.body))
                    .foregroundStyle(task.isCompleted ? .tertiary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                if let due = task.dueDate, !task.isCompleted {
                    Text(due.shortFormatted)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(due < Date() ? .red : .secondary)
                }
            }

            Spacer()

            if task.priority != .p4 {
                Circle()
                    .fill(Color.priorityColor(task.priority))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
