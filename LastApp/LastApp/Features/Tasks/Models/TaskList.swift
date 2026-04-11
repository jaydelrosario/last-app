// LastApp/Features/Tasks/Models/TaskList.swift
import SwiftData
import Foundation

@Model
final class TaskList {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "list.bullet"
    var colorHex: String = "14b8a6"
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list) var tasks: [TaskItem] = []

    init(name: String, icon: String = "list.bullet", colorHex: String = "14b8a6") {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
