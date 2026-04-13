// LastApp/LastApp/Features/Cooking/Views/CollectionListView.swift
import SwiftUI
import SwiftData

struct CollectionListView: View {
    @Query(sort: \RecipeCollection.name) private var collections: [RecipeCollection]
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Environment(\.modelContext) private var modelContext

    @State private var newCollectionName = ""
    @State private var selectedCollection: RecipeCollection? = nil

    var body: some View {
        List {
            // New collection section
            Section("New Collection") {
                HStack {
                    TextField("Collection name", text: $newCollectionName)
                    Button("Add") {
                        addCollection()
                    }
                    .disabled(newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(Color.appAccent)
                }
            }

            // Existing collections
            Section("Collections") {
                if collections.isEmpty {
                    Text("No collections yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(collections) { collection in
                        Button {
                            selectedCollection = collection
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.name)
                                        .foregroundStyle(.primary)
                                    Text("\(collection.recipes.count) recipe\(collection.recipes.count == 1 ? "" : "s")")
                                        .font(.system(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(.caption, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCollections)
                }
            }
        }
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedCollection) { collection in
            CollectionDetailView(collection: collection, allRecipes: allRecipes)
        }
    }

    private func addCollection() {
        let name = newCollectionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let collection = RecipeCollection(name: name)
        modelContext.insert(collection)
        try? modelContext.save()
        newCollectionName = ""
    }

    private func deleteCollections(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(collections[i]) }
        try? modelContext.save()
    }
}

struct CollectionDetailView: View {
    @Bindable var collection: RecipeCollection
    let allRecipes: [Recipe]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(allRecipes) { recipe in
                let isInCollection = collection.recipes.contains { $0.id == recipe.id }
                Button {
                    toggleRecipe(recipe, in: collection, isIn: isInCollection)
                } label: {
                    HStack {
                        Text(recipe.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isInCollection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.appAccent)
                                .font(.system(.body, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func toggleRecipe(_ recipe: Recipe, in collection: RecipeCollection, isIn: Bool) {
        if isIn {
            collection.recipes.removeAll { $0.id == recipe.id }
        } else {
            collection.recipes.append(recipe)
        }
        try? modelContext.save()
    }
}
