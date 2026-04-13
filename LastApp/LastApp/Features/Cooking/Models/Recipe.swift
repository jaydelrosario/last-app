// LastApp/LastApp/Features/Cooking/Models/Recipe.swift
import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var title: String
    var desc: String?
    var photoData: Data?
    var prepMinutes: Int
    var cookMinutes: Int
    var baseServings: Int
    var createdAt: Date
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient] = []

    @Relationship(deleteRule: .cascade, inverse: \RecipeStep.recipe)
    var steps: [RecipeStep] = []

    @Relationship(inverse: \RecipeCollection.recipes)
    var collections: [RecipeCollection] = []

    init(title: String, prepMinutes: Int = 0, cookMinutes: Int = 0, baseServings: Int = 2) {
        self.id = UUID()
        self.title = title
        self.desc = nil
        self.photoData = nil
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.baseServings = baseServings
        self.createdAt = Date()
        self.isFavorite = false
    }
}
