// LastApp/LastApp/Features/Workout/Models/Routine.swift
import SwiftData
import Foundation

@Model
final class Routine {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine)
    var entries: [RoutineEntry] = []

    var orderedEntries: [RoutineEntry] {
        entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// First 3 exercise names joined by ", "
    var exerciseSummary: String {
        orderedEntries.prefix(3).compactMap { $0.exercise?.name }.joined(separator: ", ")
    }

    init(name: String) {
        self.name = name
    }
}
