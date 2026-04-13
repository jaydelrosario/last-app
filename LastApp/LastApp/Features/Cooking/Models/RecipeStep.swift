// LastApp/LastApp/Features/Cooking/Models/RecipeStep.swift
import Foundation
import SwiftData

@Model
final class RecipeStep {
    var id: UUID
    var sortOrder: Int
    var instruction: String
    var timerSeconds: Int?
    var recipe: Recipe?

    init(sortOrder: Int, instruction: String, timerSeconds: Int? = nil) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.instruction = instruction
        self.timerSeconds = timerSeconds
    }
}
