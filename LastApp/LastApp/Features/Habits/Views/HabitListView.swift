// LastApp/Features/Habits/Views/HabitListView.swift
import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitStack.createdAt) private var stacks: [HabitStack]
    @State private var showingCreation = false
    @State private var showingStackCreation = false
    @State private var editingStack: HabitStack?

    private var viewModel: HabitViewModel {
        HabitViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if habits.isEmpty && stacks.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }

            // FAB — menu with New Habit / New Stack
            Menu {
                Button {
                    showingCreation = true
                } label: {
                    Label("New Habit", systemImage: "flame")
                }

                Button {
                    showingStackCreation = true
                } label: {
                    Label("New Habit Stack", systemImage: "square.stack")
                }
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
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreation) {
            HabitCreationView()
        }
        .sheet(isPresented: $showingStackCreation) {
            HabitStackView()
        }
        .sheet(item: $editingStack) { stack in
            HabitStackView(existingStack: stack)
        }
    }

    private var habitList: some View {
        List {
            // Individual habits
            if !habits.isEmpty {
                Section {
                    ForEach(habits) { habit in
                        NavigationLink(value: habit) {
                            HabitRowView(habit: habit) {
                                withAnimation { viewModel.toggleToday(habit) }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        offsets.map { habits[$0] }.forEach { viewModel.delete($0) }
                    }
                } header: {
                    Text("HABITS")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .listSectionSeparator(.hidden)
            }

            // Habit stacks
            if !stacks.isEmpty {
                Section {
                    ForEach(stacks) { stack in
                        HabitStackRowView(stack: stack) {
                            editingStack = stack
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        offsets.map { stacks[$0] }.forEach { modelContext.delete($0) }
                    }
                } header: {
                    Text("STACKS")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Habit.self) { habit in
            HabitDetailView(habit: habit)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 48))
            Text("Start your first habit")
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
