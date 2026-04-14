// LastApp/Features/Notes/Models/Note.swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    /// Archived NSAttributedString
    var bodyData: Data = Data()
    /// Plain text extracted from bodyData — updated by NoteEditorView on save
    var plainText: String = ""
    var isPinned: Bool = false
    var tags: [String] = []

    @Relationship(deleteRule: .nullify, inverse: \NoteNotebook.notes)
    var notebook: NoteNotebook?

    /// First non-empty line of plainText, fallback "New Note"
    var title: String {
        let line = plainText
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return line.map { String($0.prefix(80)) } ?? "New Note"
    }

    /// Second non-empty line of plainText
    var subtitle: String {
        let lines = plainText
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return "" }
        return String(lines[1].prefix(60))
    }

    init() {}
}
