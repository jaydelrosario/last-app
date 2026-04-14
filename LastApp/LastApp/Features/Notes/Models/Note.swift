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
    var isPinned: Bool = false
    var tags: [String] = []

    @Relationship(deleteRule: .nullify, inverse: \NoteNotebook.notes)
    var notebook: NoteNotebook?

    /// First non-empty line of plain text body, fallback "New Note"
    var title: String {
        guard let attr = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self, from: bodyData
        ) else { return "New Note" }
        let line = attr.string
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return line.map { String($0.prefix(80)) } ?? "New Note"
    }

    /// Second non-empty line (used as subtitle in list rows)
    var subtitle: String {
        guard let attr = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self, from: bodyData
        ) else { return "" }
        let lines = attr.string
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return "" }
        return String(lines[1].prefix(60))
    }

    init() {}
}
