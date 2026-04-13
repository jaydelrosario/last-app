// LastApp/LastApp/Features/Cooking/Views/RecipeDetailView.swift
import SwiftUI
import UIKit

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var selectedServings: Int
    @State private var showingCookMode = false

    init(recipe: Recipe) {
        self.recipe = recipe
        self._selectedServings = State(initialValue: recipe.baseServings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroImage
                titleCard
                Divider().padding(.horizontal, AppTheme.padding)
                servingsStepper
                Divider().padding(.horizontal, AppTheme.padding)
                ingredientsSection
                Divider().padding(.horizontal, AppTheme.padding)
                stepsSection
                startCookingButton
                Spacer(minLength: 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    recipe.isFavorite.toggle()
                } label: {
                    Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(recipe.isFavorite ? .yellow : .secondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showingCookMode) {
            NavigationStack { CookModeView(recipe: recipe) }
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        if let photoData = recipe.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
        }
    }

    // MARK: - Title Card

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.system(.title2, weight: .bold))

            HStack(spacing: 16) {
                Label("\(recipe.prepMinutes) min prep", systemImage: "clock")
                Label("\(recipe.cookMinutes) min cook", systemImage: "flame")
            }
            .font(.system(.subheadline))
            .foregroundStyle(.secondary)

            if let desc = recipe.desc, !desc.isEmpty {
                Text(desc)
                    .font(.system(.body))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.padding)
    }

    // MARK: - Servings Stepper

    private var servingsStepper: some View {
        HStack {
            Text("Servings")
                .font(.system(.body, weight: .semibold))
            Spacer()
            HStack(spacing: 12) {
                Button {
                    if selectedServings > 1 { selectedServings -= 1 }
                } label: {
                    Image(systemName: "minus").frame(width: 32, height: 32)
                }
                Text("\(selectedServings)")
                    .font(.system(.body, weight: .medium))
                    .frame(minWidth: 28)
                Button {
                    selectedServings += 1
                } label: {
                    Image(systemName: "plus").frame(width: 32, height: 32)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(AppTheme.padding)
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients")
                .font(.system(.body, weight: .semibold))
                .padding(.horizontal, AppTheme.padding)

            ForEach(recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }) { ingredient in
                let scale = Double(selectedServings) / Double(max(1, recipe.baseServings))
                let scaledAmount = ingredient.amount * scale
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(formatAmount(scaledAmount) + (ingredient.unit.map { " \($0)" } ?? "") + " " + ingredient.name)
                        .font(.system(.body))
                }
                .padding(.horizontal, AppTheme.padding)
            }
        }
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.system(.body, weight: .semibold))
                .padding(.horizontal, AppTheme.padding)

            ForEach(Array(recipe.steps.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.appAccent, in: Circle())
                    Text(step.instruction)
                        .font(.system(.body))
                }
                .padding(.horizontal, AppTheme.padding)
            }
        }
    }

    // MARK: - Start Cooking Button

    private var startCookingButton: some View {
        Button {
            showingCookMode = true
        } label: {
            Label("Start Cooking", systemImage: "play.fill")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(AppTheme.padding)
        .disabled(recipe.steps.isEmpty)
    }

    // MARK: - Helpers

    private func formatAmount(_ value: Double) -> String {
        let v = abs(value)
        if v == v.rounded() { return String(Int(v.rounded())) }
        return String(format: "%.1f", v)
    }
}
