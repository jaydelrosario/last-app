// LastApp/LastApp/Features/Workout/Models/Exercise.swift
import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupRaw: String = MuscleGroup.chest.rawValue
    var equipmentRaw: String = Equipment.barbell.rawValue
    var isCustom: Bool = false
    var createdAt: Date = Date()

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }

    init(name: String, muscleGroup: MuscleGroup, equipment: Equipment, isCustom: Bool = false) {
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.isCustom = isCustom
    }
}
