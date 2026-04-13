// LastApp/LastApp/Features/Cooking/Models/RecipeCollection.swift
import Foundation
import SwiftData

@Model
final class RecipeCollection {
    var id: UUID
    var name: String
    var recipes: [Recipe] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
