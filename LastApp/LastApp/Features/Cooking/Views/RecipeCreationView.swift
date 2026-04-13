// LastApp/LastApp/Features/Cooking/Views/RecipeCreationView.swift
import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Draft Models (form state only, not SwiftData)

struct DraftIngredient: Identifiable {
    var id = UUID()
    var amount: String = ""
    var unit: String = ""
    var name: String = ""
}

struct DraftStep: Identifiable {
    var id = UUID()
    var instruction: String = ""
}

// MARK: - View

struct RecipeCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var title = ""
    @State private var desc = ""
    @State private var prepMinutes = 0
    @State private var cookMinutes = 0
    @State private var baseServings = 2
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    // Dynamic rows
    @State private var ingredients: [DraftIngredient] = [DraftIngredient()]
    @State private var steps: [DraftStep] = [DraftStep()]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    photoPicker
                }
                Section("Details") {
                    TextField("Recipe name", text: $title)
                    TextField("Description (optional)", text: $desc, axis: .vertical)
                        .lineLimit(2...4)
                    Stepper("\(prepMinutes) min prep", value: $prepMinutes, in: 0...300, step: 5)
                    Stepper("\(cookMinutes) min cook", value: $cookMinutes, in: 0...600, step: 5)
                    Stepper("\(baseServings) serving\(baseServings == 1 ? "" : "s")", value: $baseServings, in: 1...100)
                }
                Section("Ingredients") {
                    ingredientRows
                    addIngredientButton
                }
                Section("Steps") {
                    stepRows
                    addStepButton
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "photo")
                    Text("Add Photo")
                }
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                photoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    // MARK: - Ingredient Rows

    private var ingredientRows: some View {
        ForEach($ingredients) { $ingredient in
            HStack(spacing: 8) {
                TextField("1.5", text: $ingredient.amount)
                    .keyboardType(.decimalPad)
                    .frame(width: 50)
                TextField("cups", text: $ingredient.unit)
                    .frame(width: 60)
                TextField("flour", text: $ingredient.name)
                    .frame(maxWidth: .infinity)
                Button {
                    ingredients.removeAll { $0.id == ingredient.id }
                } label: {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                }
                .disabled(ingredients.count <= 1)
            }
        }
    }

    private var addIngredientButton: some View {
        Button("+ Add ingredient") {
            ingredients.append(DraftIngredient())
        }
        .foregroundStyle(Color.appAccent)
    }

    // MARK: - Step Rows

    private var stepRows: some View {
        ForEach($steps) { $step in
            HStack(alignment: .top, spacing: 8) {
                Text("\(steps.firstIndex(where: { $0.id == step.id })! + 1).")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                TextField("Step instruction…", text: $step.instruction, axis: .vertical)
                    .lineLimit(2...5)
                Button {
                    steps.removeAll { $0.id == step.id }
                } label: {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                }
                .disabled(steps.count <= 1)
            }
        }
    }

    private var addStepButton: some View {
        Button("+ Add step") {
            steps.append(DraftStep())
        }
        .foregroundStyle(Color.appAccent)
    }

    // MARK: - Save

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private func save() {
        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            baseServings: baseServings
        )
        recipe.desc = desc.isEmpty ? nil : desc
        recipe.photoData = photoData

        for (i, draft) in ingredients.enumerated() {
            let name = draft.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            let amount = Double(draft.amount) ?? 0
            let unit = draft.unit.trimmingCharacters(in: .whitespaces)
            let ingredient = Ingredient(sortOrder: i, amount: amount, unit: unit.isEmpty ? nil : unit, name: name)
            recipe.ingredients.append(ingredient)
            modelContext.insert(ingredient)
        }

        for (i, draft) in steps.enumerated() {
            let instruction = draft.instruction.trimmingCharacters(in: .whitespaces)
            guard !instruction.isEmpty else { continue }
            let step = RecipeStep(sortOrder: i, instruction: instruction)
            recipe.steps.append(step)
            modelContext.insert(step)
        }

        modelContext.insert(recipe)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    RecipeCreationView()
        .modelContainer(for: [Recipe.self, Ingredient.self, RecipeStep.self], inMemory: true)
}
