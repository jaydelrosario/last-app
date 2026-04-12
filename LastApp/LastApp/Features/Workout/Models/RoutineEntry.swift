// LastApp/LastApp/Features/Workout/Models/RoutineEntry.swift
import SwiftData
import Foundation

@Model
final class RoutineEntry {
    var id: UUID = UUID()
    var setCount: Int = 3
    var sortOrder: Int = 0

    var routine: Routine?
    var exercise: Exercise?

    init(exercise: Exercise, setCount: Int = 3, sortOrder: Int = 0) {
        self.exercise = exercise
        self.setCount = setCount
        self.sortOrder = sortOrder
    }
}
