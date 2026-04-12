// LastApp/LastApp/Features/Workout/Models/WorkoutSession.swift
import SwiftData
import Foundation

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var finishedAt: Date? = nil
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var sessionExercises: [SessionExercise] = []

    var isActive: Bool { finishedAt == nil }

    var orderedExercises: [SessionExercise] {
        sessionExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    init() {}
}
