// LastApp/Features/Tasks/Models/TaskFolder.swift
import Foundation
import SwiftData

@Model
final class TaskFolder {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var isExpanded: Bool

    @Relationship(deleteRule: .nullify, inverse: \TaskList.folder)
    var lists: [TaskList] = []

    init(name: String, colorHex: String = "") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = 0
        self.isExpanded = true
    }
}
