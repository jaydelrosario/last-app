// LastApp/LastApp/Features/Workout/Models/Equipment.swift
import Foundation

enum Equipment: String, CaseIterable, Codable {
    case barbell, dumbbell, machine, bodyweight, cable, kettlebell, other

    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .bodyweight: "Bodyweight"
        case .cable: "Cable"
        case .kettlebell: "Kettlebell"
        case .other: "Other"
        }
    }
}
