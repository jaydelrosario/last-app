// LastApp/Features/Tasks/Views/TodayView.swift
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingTaskCreation = false

    private var taskVM: TaskViewModel { TaskViewModel(context: modelContext) }
    private var habitVM: HabitViewModel { HabitViewModel(context: modelContext) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !habits.isEmpty {
                        habitsSection
                    }
                    tasksSection
                }
            }

            Button {
                showingTaskCreation = true
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
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingTaskCreation) {
            TaskCreationView()
        }
    }

    // MARK: - Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("HABITS")
            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Button {
                        withAnimation { habitVM.toggleToday(habit) }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(habit.isCompletedToday ? Color.appAccent : Color.clear)
                                .frame(width: 24, height: 24)
                            Circle()
                                .strokeBorder(
                                    habit.isCompletedToday ? Color.appAccent : Color.secondary.opacity(0.4),
                                    lineWidth: 1.5
                                )
                                .frame(width: 24, height: 24)
                            if habit.isCompletedToday {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text(habit.name)
                        .font(.system(.body))
                        .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                    Spacer()

                    if habit.streak > 0 {
                        Text("🔥 \(habit.streak)")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)

                Divider()
                    .padding(.leading, AppTheme.padding + 24 + 12)
            }
        }
    }

    // MARK: - Tasks

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("TASKS")

            if todayTasks.isEmpty {
                HStack {
                    Spacer()
                    Text("Nothing due today")
                        .font(.system(.subheadline))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(todayTasks) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task) {
                            withAnimation { taskVM.toggleComplete(task) }
                        }
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .padding(.leading, AppTheme.padding + 22 + 14)
                }
            }
        }
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var todayTasks: [TaskItem] {
        allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 <= Date().endOfDay } ?? false) }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environment(AppState())
    .modelContainer(for: [TaskItem.self, Habit.self, HabitLog.self], inMemory: true)
}
