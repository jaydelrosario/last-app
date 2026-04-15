// LastApp/Features/Cooking/Views/CookingTemplatesView.swift
import SwiftUI
import SwiftData

struct CookingTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var addedTemplates: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(CookingTemplates.groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.templates, id: \.title) { template in
                            templateRow(template)
                        }
                    }
                }
            }
            .navigationTitle("Recipe Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func templateRow(_ template: CookingTemplateItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(template.title)
                    .font(.system(.body, weight: .semibold))
                let time = totalTime(template)
                if !time.isEmpty {
                    Text(time)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
                Text(template.desc)
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            if addedTemplates.contains(template.title) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appAccent)
                    .font(.system(.title3))
            } else {
                Button {
                    addTemplate(template)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.appAccent)
                        .font(.system(.title3))
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private func totalTime(_ template: CookingTemplateItem) -> String {
        let total = template.prepMinutes + template.cookMinutes
        guard total > 0 else { return "No cook" }
        if total < 60 { return "\(total) min" }
        let h = total / 60; let m = total % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }

    private func addTemplate(_ template: CookingTemplateItem) {
        let recipe = Recipe(
            title: template.title,
            prepMinutes: template.prepMinutes,
            cookMinutes: template.cookMinutes,
            baseServings: template.servings
        )
        recipe.desc = template.desc
        modelContext.insert(recipe)

        for (i, ing) in template.ingredients.enumerated() {
            let ingredient = Ingredient(sortOrder: i, amount: ing.amount, unit: ing.unit, name: ing.name)
            ingredient.recipe = recipe
            modelContext.insert(ingredient)
        }

        for (i, instruction) in template.steps.enumerated() {
            let step = RecipeStep(sortOrder: i, instruction: instruction)
            step.recipe = recipe
            modelContext.insert(step)
        }

        try? modelContext.save()
        addedTemplates.insert(template.title)
    }
}
