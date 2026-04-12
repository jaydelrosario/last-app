// LastApp/LastApp/Features/Workout/Models/MuscleGroup.swift
import Foundation

enum MuscleGroup: String, CaseIterable, Codable {
    case chest, back, shoulders, biceps, triceps, legs, core, cardio

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .legs: "Legs"
        case .core: "Core"
        case .cardio: "Cardio"
        }
    }

    var sortOrder: Int {
        switch self {
        case .chest: 0
        case .back: 1
        case .shoulders: 2
        case .biceps: 3
        case .triceps: 4
        case .legs: 5
        case .core: 6
        case .cardio: 7
        }
    }
}
