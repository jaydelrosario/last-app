// LastApp/Features/Habits/Views/HabitTemplatesView.swift
import SwiftUI
import SwiftData

struct HabitTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var addedTemplates: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(HabitTemplates.groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.templates, id: \.name) { template in
                            templateRow(template)
                        }
                    }
                }
            }
            .navigationTitle("Habit Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func templateRow(_ template: HabitTemplateItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(template.action)
                    .font(.system(.body, weight: .semibold))
                Text(scheduleLabel(template))
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
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

    private func scheduleLabel(_ template: HabitTemplateItem) -> String {
        let days = template.scheduleDays
        if days.isEmpty { return "every day" }
        if Set(days) == Set([1,2,3,4,5]) { return "weekdays" }
        if Set(days) == Set([0,6]) { return "weekends" }
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return days.map { names[$0] }.joined(separator: ", ")
    }

    private func addTemplate(_ template: HabitTemplateItem) {
        let habit = Habit(name: template.name)
        habit.action = template.action
        habit.goalCount = template.goalCount
        habit.goalUnit = template.goalUnit
        if !template.scheduleDays.isEmpty {
            habit.scheduleDays = template.scheduleDays
        }
        modelContext.insert(habit)
        try? modelContext.save()
        addedTemplates.insert(template.name)
    }
}
