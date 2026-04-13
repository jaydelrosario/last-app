// LastApp/LastApp/Features/Cooking/Models/Ingredient.swift
import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID
    var sortOrder: Int
    var amount: Double
    var unit: String?
    var name: String
    var recipe: Recipe?

    init(sortOrder: Int, amount: Double, unit: String? = nil, name: String) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.amount = amount
        self.unit = unit
        self.name = name
    }
}
