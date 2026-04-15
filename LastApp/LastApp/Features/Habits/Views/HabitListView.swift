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
    @State private var selectedHabit: Habit?
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday: Bool = false

    private var viewModel: HabitViewModel {
        HabitViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            Group {
                if habits.isEmpty && stacks.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }

            // FAB — menu with New Habit / New Stack
            Menu {
                Button { showingCreation = true } label: {
                    Label("New Habit", systemImage: "flame")
                }
                Button { showingStackCreation = true } label: {
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
        .sheet(isPresented: $showingCreation) { HabitCreationView() }
        .sheet(isPresented: $showingStackCreation) { HabitStackView() }
        .sheet(item: $editingStack) { stack in HabitStackView(existingStack: stack) }
        .navigationDestination(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit)
        }
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // Determine start of week based on preference
        let firstWeekday = weekStartsOnMonday ? 2 : 1 // 1=Sun, 2=Mon
        let weekday = calendar.component(.weekday, from: today)
        let daysFromStart = (weekday - firstWeekday + 7) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromStart, to: today)!
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let dayNum = calendar.component(.day, from: day)
                let weekdayIndex = calendar.component(.weekday, from: day) - 1
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = calendar.startOfDay(for: day)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayNames[weekdayIndex])
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(isSelected ? .primary : .tertiary)
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(isToday ? Color.primary : Color.appAccent)
                                    .frame(width: 28, height: 28)
                            }
                            Text("\(dayNum)")
                                .font(.system(.subheadline, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .secondary)
                        }
                        .frame(width: 28, height: 28)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Habit list

    private var habitList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                weekStrip

                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HABITS")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, AppTheme.padding)

                        ForEach(habits) { habit in
                            HabitRowView(habit: habit, date: selectedDate) {
                                withAnimation { viewModel.toggle(habit, for: selectedDate) }
                            }
                            .padding(.horizontal, AppTheme.padding)
                            .onTapGesture { selectedHabit = habit }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.delete(habit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if !stacks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STACKS")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, AppTheme.padding)

                        ForEach(stacks) { stack in
                            HabitStackRowView(stack: stack, date: selectedDate, onEdit: {
                                editingStack = stack
                            }, onToggle: { habit in
                                withAnimation { viewModel.toggle(habit, for: selectedDate) }
                            })
                            .padding(.horizontal, AppTheme.padding)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(stack)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 90)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 52))
                .foregroundStyle(Color.orange.opacity(0.3))
            VStack(spacing: 6) {
                Text("No habits yet")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Build streaks by tracking daily actions")
                    .font(.system(.subheadline))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showingCreation = true
            } label: {
                Text("Add Habit")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.appAccent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
