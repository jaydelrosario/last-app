// LastApp/Features/Notes/Models/NoteNotebook.swift
import Foundation
import SwiftData

@Model
final class NoteNotebook {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = ""
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify)
    var notes: [Note] = []

    init(name: String, colorHex: String = "", sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
