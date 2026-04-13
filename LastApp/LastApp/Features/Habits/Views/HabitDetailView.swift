// LastApp/Features/Habits/Views/HabitDetailView.swift
import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scheduleDays: Set<Int> = []
    @State private var habitTimeEnabled = false
    @State private var habitTime: Date = .now
    @State private var reminderEnabled = false
    @State private var reminderOffset = 0

    private let weekdayLabels = ["S","M","T","W","T","F","S"]
    private let goalUnits = ["time","pages","minutes","hours","steps","km","reps"]
    private let reminderOptions = [(0,"At the habit time"),(5,"5 minutes before"),(10,"10 minutes before"),(15,"15 minutes before"),(30,"30 minutes before")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sentencePreview
                actionField
                identityField
                Divider().padding(.horizontal, AppTheme.padding)
                repeatSection
                Divider().padding(.horizontal, AppTheme.padding)
                goalSection
                Divider().padding(.horizontal, AppTheme.padding)
                timeSection
                if habitTimeEnabled {
                    Divider().padding(.horizontal, AppTheme.padding)
                    reminderSection
                }
                Divider().padding(.horizontal, AppTheme.padding)
                statsSection
                Divider().padding(.horizontal, AppTheme.padding)
                completionHistorySection
                Spacer(minLength: 32)
            }
            .padding(.top, AppTheme.padding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        HabitNotificationManager.cancel(for: habit)
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
        .onAppear { loadState() }
        .onDisappear { saveState() }
    }

    // MARK: - Sentence Preview

    private var sentencePreview: some View {
        Text(sentenceAttributed)
            .font(.system(.title3))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.padding)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, AppTheme.padding)
    }

    private var sentenceAttributed: AttributedString {
        var s = AttributedString("I will ")
        s.foregroundColor = .secondary

        var a = AttributedString(habit.action.isEmpty ? "______" : habit.action)
        a.foregroundColor = .orange
        a.underlineStyle = .single

        var comma = AttributedString(", ")
        comma.foregroundColor = .secondary

        var sched = AttributedString(habit.scheduleText)
        sched.foregroundColor = .purple
        sched.underlineStyle = .single

        var become = AttributedString(" so that I can become ")
        become.foregroundColor = .secondary

        var id = AttributedString(habit.identity.isEmpty ? "______" : habit.identity)
        id.foregroundColor = .indigo
        id.underlineStyle = .single

        var period = AttributedString(".")
        period.foregroundColor = .secondary

        return s + a + comma + sched + become + id + period
    }

    // MARK: - Fields

    private var actionField: some View {
        inputSection(label: "I will…") {
            TextField("read 10 pages", text: $habit.action)
        }
    }

    private var identityField: some View {
        inputSection(label: "So I can become…") {
            TextField("a sharper, continuously learning person", text: $habit.identity, axis: .vertical)
                .lineLimit(2)
        }
    }

    // MARK: - Repeat

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repeat")
                    .font(.system(.body, weight: .semibold))
                Spacer()
                Text(repeatLabel)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppTheme.padding)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    let on = scheduleDays.contains(day)
                    Button {
                        if on, scheduleDays.count > 1 { scheduleDays.remove(day) }
                        else { scheduleDays.insert(day) }
                    } label: {
                        Text(weekdayLabels[day])
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(on ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(on ? Color.appAccent : Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily goal")
                .font(.system(.body, weight: .semibold))
                .padding(.horizontal, AppTheme.padding)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Button { if habit.goalCount > 1 { habit.goalCount -= 1 } } label: {
                        Image(systemName: "minus").frame(width: 32, height: 32)
                    }
                    Text("\(habit.goalCount)")
                        .font(.system(.body, weight: .medium))
                        .frame(minWidth: 28)
                    Button { habit.goalCount += 1 } label: {
                        Image(systemName: "plus").frame(width: 32, height: 32)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                Picker("", selection: $habit.goalUnit) {
                    ForEach(goalUnits, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                Spacer()
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit time")
                .font(.system(.body, weight: .semibold))
                .padding(.horizontal, AppTheme.padding)

            HStack(spacing: 12) {
                if habitTimeEnabled {
                    DatePicker("", selection: $habitTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    withAnimation(.spring(response: 0.3)) { habitTimeEnabled.toggle() }
                } label: {
                    Label(habitTimeEnabled ? "Remove" : "Add", systemImage: habitTimeEnabled ? "minus" : "plus")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Send reminder")
                    .font(.system(.body, weight: .semibold))
                Spacer()
                Toggle("", isOn: $reminderEnabled)
                    .tint(Color.appAccent)
                    .labelsHidden()
            }
            .padding(.horizontal, AppTheme.padding)

            if reminderEnabled {
                VStack(spacing: 0) {
                    ForEach(reminderOptions, id: \.0) { minutes, label in
                        Button {
                            reminderOffset = minutes
                        } label: {
                            HStack {
                                Text(label).foregroundStyle(.primary)
                                Spacer()
                                if reminderOffset == minutes {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appAccent)
                                        .font(.system(.body, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, AppTheme.padding)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if minutes != reminderOptions.last?.0 {
                            Divider().padding(.leading, AppTheme.padding)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, AppTheme.padding)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 32) {
            statPill(label: "Streak", value: "\(habit.streak) \(habit.streak == 1 ? "day" : "days")")
            statPill(label: "Started", value: habit.createdAt.shortFormatted)
        }
        .padding(.horizontal, AppTheme.padding)
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

    // MARK: - Completion History (30-day grid)

    private var completionHistorySection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<30).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
        let completedDays = Set(habit.logs.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })

        return VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 days")
                .font(.system(.body, weight: .semibold))
                .padding(.horizontal, AppTheme.padding)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(days, id: \.self) { day in
                    let completed = completedDays.contains(day)
                    let isToday = calendar.isDate(day, inSameDayAs: today)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(completed ? habit.accentColor : Color.secondary.opacity(0.12))
                        .overlay(
                            isToday && !completed
                                ? RoundedRectangle(cornerRadius: 5).strokeBorder(habit.accentColor.opacity(0.5), lineWidth: 1.5)
                                : nil
                        )
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Helpers

    private func inputSection<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppTheme.padding)
            content()
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, AppTheme.padding)
        }
    }

    private var repeatLabel: String {
        if scheduleDays.count == 7 { return "Daily" }
        if Set(scheduleDays) == Set([1,2,3,4,5]) { return "Weekdays" }
        if Set(scheduleDays) == Set([0,6]) { return "Weekends" }
        return "Custom"
    }

    private func loadState() {
        scheduleDays = Set(habit.scheduleDays)
        habitTimeEnabled = habit.habitTimeInterval >= 0
        if habit.habitTimeInterval >= 0 {
            habitTime = Calendar.current.startOfDay(for: .now).addingTimeInterval(habit.habitTimeInterval)
        }
        reminderEnabled = habit.reminderEnabled
        reminderOffset = habit.reminderOffsetMinutes
    }

    private func saveState() {
        habit.scheduleDays = scheduleDays.sorted()
        habit.habitTimeInterval = habitTimeEnabled
            ? habitTime.timeIntervalSince(Calendar.current.startOfDay(for: habitTime))
            : -1
        habit.reminderEnabled = reminderEnabled && habitTimeEnabled
        habit.reminderOffsetMinutes = reminderOffset
        HabitNotificationManager.cancel(for: habit)
        if habit.reminderEnabled {
            HabitNotificationManager.schedule(for: habit)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    let habit = Habit(name: "Read", frequency: .daily)
    habit.action = "read 10 pages"
    habit.identity = "a sharper, continuously learning person"
    container.mainContext.insert(habit)
    return NavigationStack { HabitDetailView(habit: habit) }
        .modelContainer(container)
}
