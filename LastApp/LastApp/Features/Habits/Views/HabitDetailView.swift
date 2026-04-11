// LastApp/Features/Habits/Views/HabitDetailView.swift
import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<30).compactMap { offset in
            calendar.date(byAdding: .day, value: -(29 - offset), to: today)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TextField("Habit name", text: $habit.name)
                    .font(.system(.title2, weight: .semibold))
                    .padding(.horizontal, AppTheme.padding)

                Picker("Frequency", selection: Binding(
                    get: { habit.frequency },
                    set: { habit.frequencyRaw = $0.rawValue }
                )) {
                    ForEach(Frequency.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.padding)

                HStack(spacing: 24) {
                    statPill(label: "Streak", value: "\(habit.streak) \(habit.streak == 1 ? "day" : "days")")
                    statPill(label: "Started", value: habit.createdAt.shortFormatted)
                }
                .padding(.horizontal, AppTheme.padding)

                calendarGrid
            }
            .padding(.vertical, AppTheme.padding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(habit)
                        dismiss()
                    } label: {
                        Label("Delete Habit", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 30 days")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppTheme.padding)

            HStack(spacing: 6) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.quaternary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.padding)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Color.clear.frame(width: 28, height: 28)
                }
                ForEach(last30Days, id: \.self) { day in
                    let done = isCompleted(day)
                    Circle()
                        .fill(done ? Color.appAccent : Color.secondary.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day.isToday {
                                Circle()
                                    .strokeBorder(Color.appAccent.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                }
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    private var leadingEmptyCells: Int {
        guard let first = last30Days.first else { return 0 }
        return Calendar.current.component(.weekday, from: first) - 1
    }

    private func isCompleted(_ date: Date) -> Bool {
        habit.logs.contains {
            $0.isCompleted && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(.subheadline, weight: .semibold))
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    let habit = Habit(name: "Read daily", frequency: .daily)
    container.mainContext.insert(habit)
    return NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(container)
}
