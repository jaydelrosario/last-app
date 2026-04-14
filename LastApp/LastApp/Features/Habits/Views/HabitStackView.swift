// LastApp/Features/Habits/Views/HabitStackView.swift
import SwiftUI
import SwiftData

struct HabitStackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    var existingStack: HabitStack? = nil

    @State private var cueHabit: Habit?
    @State private var nextHabits: [Habit?] = [nil]
    @State private var selectingSlot: SlotID?

    struct SlotID: Identifiable { let id: Int }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    descriptionCard

                    // Cue habit
                    habitSection(
                        title: "My cue habit",
                        subtitle: "This will be the first habit in your habit stack",
                        habit: cueHabit,
                        slot: 0
                    )

                    Divider()

                    // Next habits
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next habit")
                                .font(.system(.body, weight: .bold))
                            Text("Chain one or more existing habits to create your habit stack")
                                .font(.system(.subheadline))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(Array(nextHabits.enumerated()), id: \.offset) { i, habit in
                            habitPickerRow(habit: habit, slot: i + 1)
                        }

                        Button {
                            withAnimation { nextHabits.append(nil) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(.body, weight: .semibold))
                                Text("Add another habit")
                                    .font(.system(.body, weight: .semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // Save button
                    Button(action: save) {
                        Text(existingStack == nil ? "Create Stack" : "Update Stack")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(canSave ? .white : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave ? Color.appAccent : Color.secondary.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .padding(.top, 8)
                }
                .padding(AppTheme.padding)
            }
            .navigationTitle(existingStack == nil ? "New Habit Stack" : "Edit Habit Stack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(.title3))
                    }
                }
            }
        }
        .sheet(item: $selectingSlot) { slot in
            HabitPickerSheet(
                habits: habits,
                excluded: usedHabitIDs(excludingSlot: slot.id)
            ) { habit in
                if slot.id == 0 {
                    cueHabit = habit
                } else {
                    nextHabits[slot.id - 1] = habit
                }
                selectingSlot = nil
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { loadIfEditing() }
    }

    // MARK: - Sections

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a cue habit to trigger your next habit.")
                .font(.system(.body, weight: .medium))

            Button {
                // Info action — could present a how-it-works sheet
            } label: {
                HStack {
                    Image(systemName: "book")
                    Text("Show me how it works")
                }
                .font(.system(.body))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func habitSection(title: String, subtitle: String, habit: Habit?, slot: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(.body, weight: .bold))
                Text(subtitle).font(.system(.subheadline)).foregroundStyle(.secondary)
            }
            habitPickerRow(habit: habit, slot: slot)
        }
    }

    private func habitPickerRow(habit: Habit?, slot: Int) -> some View {
        Button {
            selectingSlot = SlotID(id: slot)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(habit?.accentColor ?? Color.secondary.opacity(0.25))
                    .frame(width: 22, height: 22)

                Text(habit?.displayName ?? "Select a habit")
                    .font(.system(.body, weight: habit != nil ? .semibold : .regular))
                    .foregroundStyle(habit != nil ? .primary : .secondary)
                    .lineLimit(2)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.system(.subheadline))
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var canSave: Bool {
        cueHabit != nil && nextHabits.contains(where: { $0 != nil })
    }

    private func usedHabitIDs(excludingSlot slot: Int) -> Set<UUID> {
        var ids = Set<UUID>()
        if let h = cueHabit, slot != 0 { ids.insert(h.id) }
        for (i, h) in nextHabits.enumerated() {
            if let h, slot != i + 1 { ids.insert(h.id) }
        }
        return ids
    }

    private func loadIfEditing() {
        guard let stack = existingStack else { return }
        let ordered = stack.orderedHabits
        cueHabit = ordered.first
        nextHabits = ordered.dropFirst().map { Optional($0) }
        if nextHabits.isEmpty { nextHabits = [nil] }
    }

    private func save() {
        guard let cue = cueHabit else { return }
        let validNext = nextHabits.compactMap { $0 }
        guard !validNext.isEmpty else { return }

        let stack = existingStack ?? {
            let s = HabitStack()
            modelContext.insert(s)
            return s
        }()

        // Clear existing entries if editing
        stack.entries.forEach { modelContext.delete($0) }

        let cueEntry = HabitStackEntry(sortOrder: 0, habit: cue)
        cueEntry.stack = stack
        modelContext.insert(cueEntry)

        for (i, habit) in validNext.enumerated() {
            let entry = HabitStackEntry(sortOrder: i + 1, habit: habit)
            entry.stack = stack
            modelContext.insert(entry)
        }

        dismiss()
    }
}

// MARK: - Habit Picker Sheet

struct HabitPickerSheet: View {
    let habits: [Habit]
    let excluded: Set<UUID>
    let onSelect: (Habit) -> Void

    @Environment(\.dismiss) private var dismiss

    private var available: [Habit] { habits.filter { !excluded.contains($0.id) } }

    var body: some View {
        NavigationStack {
            List {
                if available.isEmpty {
                    ContentUnavailableView(
                        "No habits available",
                        systemImage: "flame",
                        description: Text("Create more habits first")
                    )
                } else {
                    ForEach(available) { habit in
                        Button {
                            onSelect(habit)
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(habit.accentColor)
                                    .frame(width: 20, height: 20)
                                Text(habit.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HabitStackView()
        .modelContainer(for: [Habit.self, HabitLog.self, HabitStack.self, HabitStackEntry.self], inMemory: true)
}
