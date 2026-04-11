// LastApp/Features/Tasks/ViewModels/TaskViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class TaskViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addTask(title: String, notes: String = "", dueDate: Date? = nil, priority: Priority = .p4, list: TaskList? = nil) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, list: list)
        context.insert(task)
    }

    func toggleComplete(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
    }

    func delete(_ tasks: [TaskItem]) {
        tasks.forEach { context.delete($0) }
    }

    func updateSortOrder(_ tasks: [TaskItem]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }
}
