// LastApp/Features/Workout/Views/RoutineTemplatesView.swift
import SwiftUI
import SwiftData

struct RoutineTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @State private var addedTemplates: Set<String> = []

    private var exerciseByName: [String: Exercise] {
        Dictionary(exercises.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
    }

    // Group templates by split category
    private let groups: [(title: String, templates: [String])] = [
        ("Push / Pull / Legs", ["PPL – Push", "PPL – Pull", "PPL – Legs"]),
        ("Upper / Lower", ["Upper / Lower – Upper", "Upper / Lower – Lower"]),
        ("Full Body", ["Full Body A", "Full Body B"]),
        ("Bro Split", ["Chest Day", "Back Day", "Shoulder Day", "Arms Day", "Leg Day"]),
        ("Arnold Split", ["Arnold – Chest & Back", "Arnold – Shoulders & Arms", "Arnold – Legs & Core"]),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.templates, id: \.self) { templateName in
                            if let template = WorkoutSeedData.routineTemplates.first(where: { $0.name == templateName }) {
                                templateRow(template)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Routine Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func templateRow(_ template: (name: String, exercises: [String])) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.system(.body, weight: .semibold))
                Text(template.exercises.prefix(4).joined(separator: ", "))
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if addedTemplates.contains(template.name) {
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

    private func addTemplate(_ template: (name: String, exercises: [String])) {
        let routine = Routine(name: template.name)
        modelContext.insert(routine)
        for (i, exerciseName) in template.exercises.enumerated() {
            guard let exercise = exerciseByName[exerciseName] else { continue }
            let entry = RoutineEntry(exercise: exercise, setCount: 3, sortOrder: i)
            entry.routine = routine
            modelContext.insert(entry)
        }
        try? modelContext.save()
        addedTemplates.insert(template.name)
    }
}
