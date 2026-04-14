// LastApp/LastApp/Features/Workout/Views/ExercisePickerView.swift
import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let onSelect: ([Exercise]) -> Void

    @State private var selectedIDs: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var selectedEquipment: Equipment? = nil
    @State private var showingMuscleFilter = false
    @State private var showingEquipmentFilter = false
    @State private var showingCreateForm = false
    @State private var exerciseForDetail: Exercise? = nil

    // Custom exercise creation fields
    @State private var newName = ""
    @State private var newMuscle: MuscleGroup = .chest
    @State private var newEquipment: Equipment = .barbell

    private var filtered: [Exercise] {
        allExercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroup == selectedMuscle
            let matchesEquipment = selectedEquipment == nil || ex.equipment == selectedEquipment
            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }

    private var grouped: [(MuscleGroup, [Exercise])] {
        let order = MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }
        return order.compactMap { group in
            let exs = filtered.filter { $0.muscleGroup == group }
            return exs.isEmpty ? nil : (group, exs)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search exercise", text: $searchText)
                }
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Filter chips
                HStack(spacing: 10) {
                    Button {
                        showingEquipmentFilter = true
                    } label: {
                        Text(selectedEquipment?.displayName ?? "All Equipment")
                            .font(.system(.subheadline, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedEquipment != nil ? Color.appAccent.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(selectedEquipment != nil ? Color.appAccent : .primary)
                    }
                    Button {
                        showingMuscleFilter = true
                    } label: {
                        Text(selectedMuscle?.displayName ?? "All Muscles")
                            .font(.system(.subheadline, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedMuscle != nil ? Color.appAccent.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(selectedMuscle != nil ? Color.appAccent : .primary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Exercise list
                List {
                    ForEach(grouped, id: \.0) { group, exercises in
                        Section(group.displayName) {
                            ForEach(exercises) { exercise in
                                HStack {
                                    Button {
                                        if selectedIDs.contains(exercise.id) {
                                            selectedIDs.remove(exercise.id)
                                        } else {
                                            selectedIDs.insert(exercise.id)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedIDs.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedIDs.contains(exercise.id) ? Color.appAccent : .secondary)
                                                .font(.system(.title3))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(exercise.name)
                                                    .font(.system(.body, weight: .medium))
                                                    .foregroundStyle(.primary)
                                                Text(exercise.equipment.displayName)
                                                    .font(.system(.caption))
                                                    .foregroundStyle(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        exerciseForDetail = exercise
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedIDs.isEmpty ? "Add" : "Add (\(selectedIDs.count))") {
                        let exercises = allExercises.filter { selectedIDs.contains($0.id) }
                        onSelect(exercises)
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .navigationDestination(item: $exerciseForDetail) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .sheet(isPresented: $showingEquipmentFilter) {
            equipmentFilterSheet
        }
        .sheet(isPresented: $showingMuscleFilter) {
            muscleFilterSheet
        }
        .sheet(isPresented: $showingCreateForm) {
            createExerciseSheet
        }
    }

    // MARK: - Filter Sheets

    private var equipmentFilterSheet: some View {
        NavigationStack {
            List {
                Button {
                    selectedEquipment = nil
                    showingEquipmentFilter = false
                } label: {
                    HStack {
                        Text("All Equipment").foregroundStyle(.primary)
                        Spacer()
                        if selectedEquipment == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(Equipment.allCases, id: \.self) { eq in
                    Button {
                        selectedEquipment = eq
                        showingEquipmentFilter = false
                    } label: {
                        HStack {
                            Text(eq.displayName).foregroundStyle(.primary)
                            Spacer()
                            if selectedEquipment == eq {
                                Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingEquipmentFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var muscleFilterSheet: some View {
        NavigationStack {
            List {
                Button {
                    selectedMuscle = nil
                    showingMuscleFilter = false
                } label: {
                    HStack {
                        Text("All Muscles").foregroundStyle(.primary)
                        Spacer()
                        if selectedMuscle == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { group in
                    Button {
                        selectedMuscle = group
                        showingMuscleFilter = false
                    } label: {
                        HStack {
                            Text(group.displayName).foregroundStyle(.primary)
                            Spacer()
                            if selectedMuscle == group {
                                Image(systemName: "checkmark").foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingMuscleFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Create Exercise Sheet

    private var createExerciseSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $newName)
                }
                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $newMuscle) {
                        ForEach(MuscleGroup.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Equipment") {
                    Picker("Equipment", selection: $newEquipment) {
                        ForEach(Equipment.allCases, id: \.self) { eq in
                            Text(eq.displayName).tag(eq)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newName = ""
                        showingCreateForm = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = Exercise(name: newName.trimmingCharacters(in: .whitespaces),
                                               muscleGroup: newMuscle,
                                               equipment: newEquipment,
                                               isCustom: true)
                        modelContext.insert(exercise)
                        try? modelContext.save()
                        onSelect([exercise])
                        showingCreateForm = false
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
