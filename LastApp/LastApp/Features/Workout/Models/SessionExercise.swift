// LastApp/LastApp/Features/Workout/Models/SessionExercise.swift
import SwiftData
import Foundation

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var sortOrder: Int = 0

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sets: [SessionSet] = []

    var orderedSets: [SessionSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    init(exercise: Exercise, sortOrder: Int = 0) {
        self.exercise = exercise
        self.sortOrder = sortOrder
    }
}
