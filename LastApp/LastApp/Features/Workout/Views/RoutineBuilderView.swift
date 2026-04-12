// LastApp/LastApp/Features/Workout/Views/RoutineBuilderView.swift
import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pass nil to create a new routine, or an existing routine to edit it
    var existingRoutine: Routine?

    @State private var name: String = ""
    @State private var entries: [(exercise: Exercise, setCount: Int)] = []
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Routine name", text: $name)
                }

                if !entries.isEmpty {
                    Section("Exercises") {
                        ForEach(entries.indices, id: \.self) { i in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entries[i].exercise.name)
                                        .font(.system(.body, weight: .medium))
                                    Text(entries[i].exercise.muscleGroup.displayName)
                                        .font(.system(.caption))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Stepper("\(entries[i].setCount) sets",
                                        value: $entries[i].setCount,
                                        in: 1...10)
                                    .fixedSize()
                            }
                        }
                        .onDelete { indexSet in
                            entries.remove(atOffsets: indexSet)
                        }
                        .onMove { source, destination in
                            entries.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }

                Section {
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(existingRoutine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear { loadExisting() }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                entries.append((exercise: exercise, setCount: 3))
            }
        }
    }

    private func loadExisting() {
        guard let routine = existingRoutine else { return }
        name = routine.name
        entries = routine.orderedEntries.compactMap { entry in
            guard let ex = entry.exercise else { return nil }
            return (exercise: ex, setCount: entry.setCount)
        }
    }

    private func save() {
        let routine = existingRoutine ?? Routine(name: "")
        routine.name = name.trimmingCharacters(in: .whitespaces)

        // Remove old entries if editing
        for entry in routine.entries {
            modelContext.delete(entry)
        }

        // Insert new entries
        for (i, item) in entries.enumerated() {
            let entry = RoutineEntry(exercise: item.exercise, setCount: item.setCount, sortOrder: i)
            entry.routine = routine
            modelContext.insert(entry)
        }

        if existingRoutine == nil {
            modelContext.insert(routine)
        }

        try? modelContext.save()
        dismiss()
    }
}
