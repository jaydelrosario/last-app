// LastApp/Features/Tasks/Models/TaskItem.swift
import SwiftData
import Foundation

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date? = nil
    var priorityRaw: Int = Priority.p4.rawValue
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var sortOrder: Int = 0
    var tags: [String] = []
    var tickTickId: String? = nil

    @Relationship(deleteRule: .nullify) var list: TaskList?
    @Relationship(deleteRule: .cascade) var subtasks: [TaskItem] = []

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .p4 }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: Priority = .p4,
        list: TaskList? = nil
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.list = list
    }
}
