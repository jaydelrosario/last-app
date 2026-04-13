// LastApp/LastApp/Features/Cooking/Views/RecipeDetailView.swift
import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe

    var body: some View {
        Text("Detail")
            .navigationTitle(recipe.title)
    }
}
