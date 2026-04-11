// LastApp/Features/Habits/Views/HabitCreationView.swift
import SwiftUI
import SwiftData

struct HabitCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var frequency: Frequency = .daily
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit name", text: $name)
                        .focused($nameFocused)
                        .font(.system(.body))
                }

                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { nameFocused = true }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let habit = Habit(name: trimmed, frequency: frequency)
        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    HabitCreationView()
        .modelContainer(for: Habit.self, inMemory: true)
}
