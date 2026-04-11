// LastApp/Features/Habits/Views/HabitListView.swift
import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingCreation = false

    private var viewModel: HabitViewModel {
        HabitViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }

            Button {
                showingCreation = true
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
    }

    private var habitList: some View {
        List {
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

// Stubs for views implemented in later tasks
struct HabitCreationView: View { var body: some View { Text("Create Habit") } }
struct HabitDetailView: View { let habit: Habit; var body: some View { Text(habit.name) } }
