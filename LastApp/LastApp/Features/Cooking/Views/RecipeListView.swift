// LastApp/LastApp/Features/Cooking/Views/RecipeListView.swift
import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Query(sort: \RecipeCollection.name) private var collections: [RecipeCollection]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCollection: RecipeCollection? = nil
    @State private var showingCreation = false
    @State private var selectedRecipe: Recipe? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if filteredRecipes.isEmpty {
                    emptyState
                } else {
                    recipeList
                        .safeAreaInset(edge: .top, spacing: 0) {
                            if !collections.isEmpty { collectionChips }
                        }
                }
            }

            fab
        }
        .navigationTitle("Cooking")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search recipes")
        .sheet(isPresented: $showingCreation) { RecipeCreationView() }
        .navigationDestination(item: $selectedRecipe) { RecipeDetailView(recipe: $0) }
    }

    // MARK: - Filtering

    private var filteredRecipes: [Recipe] {
        var recipes = allRecipes
        if let col = selectedCollection {
            recipes = recipes.filter { $0.collections.contains { $0.id == col.id } }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            recipes = recipes.filter {
                $0.title.lowercased().contains(q) ||
                $0.ingredients.contains { $0.name.lowercased().contains(q) }
            }
        }
        return recipes
    }

    // MARK: - Time helper

    private func timeLabel(_ recipe: Recipe) -> String {
        let total = recipe.prepMinutes + recipe.cookMinutes
        if total == 0 { return "" }
        if total < 60 { return "\(total) min" }
        let h = total / 60; let m = total % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }

    // MARK: - Collection chips

    private var collectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", selected: selectedCollection == nil) {
                    selectedCollection = nil
                }
                ForEach(collections) { col in
                    chipButton(col.name, selected: selectedCollection?.id == col.id) {
                        selectedCollection = col
                    }
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func chipButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.subheadline, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.appAccent : Color(uiColor: .secondarySystemFill),
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipe list

    private var recipeList: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                recipeRow(recipe)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedRecipe = recipe }
                    .swipeActions(edge: .leading) {
                        Button {
                            recipe.isFavorite.toggle()
                            try? modelContext.save()
                        } label: {
                            Label(
                                recipe.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: recipe.isFavorite ? "star.slash.fill" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                    }
            }
            .onDelete(perform: deleteRecipes)
        }
        .listStyle(.plain)
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            Group {
                if let data = recipe.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .secondarySystemFill))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(.tertiary)
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Text info
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title)
                    .font(.system(.body, weight: .semibold))
                    .lineLimit(1)

                let time = timeLabel(recipe)
                if !time.isEmpty {
                    Text(time)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text("\(recipe.ingredients.count) ingredient\(recipe.ingredients.count == 1 ? "" : "s")")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)

                    if recipe.isFavorite {
                        Text("•")
                            .font(.system(.caption))
                            .foregroundStyle(.tertiary)
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Delete

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRecipes[index])
        }
        try? modelContext.save()
    }

    // MARK: - FAB

    private var fab: some View {
        Button {
            showingCreation = true
        } label: {
            Image(systemName: "plus")
                .font(.system(.title2, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Color.appAccent)
                .clipShape(Circle())
                .shadow(color: Color.appAccent.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(AppTheme.padding)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 52))
                .foregroundStyle(Color.appAccent.opacity(0.25))
            VStack(spacing: 6) {
                Text(searchText.isEmpty ? "No recipes yet" : "No results")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Add your first recipe to get cooking")
                    .font(.system(.subheadline))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
