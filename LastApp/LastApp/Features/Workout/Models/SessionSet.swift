// LastApp/LastApp/Features/Workout/Models/SessionSet.swift
import SwiftData
import Foundation

@Model
final class SessionSet {
    var id: UUID = UUID()
    var setNumber: Int = 1
    var weightLbs: Double = 0
    var reps: Int = 0
    var isCompleted: Bool = false

    var sessionExercise: SessionExercise?

    init(setNumber: Int) {
        self.setNumber = setNumber
    }
}
