// LastApp/Features/Habits/Views/HabitCreationView.swift
import SwiftUI
import SwiftData

struct HabitCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var action = ""
    @State private var identity = ""
    @State private var scheduleDays: Set<Int> = [0,1,2,3,4,5,6]
    @State private var goalCount = 1
    @State private var goalUnit = "time"
    @State private var habitTimeEnabled = false
    @State private var habitTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    @State private var reminderEnabled = false
    @State private var reminderOffset = 0
    @FocusState private var focusedField: InputField?

    enum InputField { case action, identity }

    private let weekdayLabels = ["S","M","T","W","T","F","S"]
    private let goalUnits = ["time","pages","minutes","hours","steps","km","reps"]
    private let reminderOptions = [(0,"At the habit time"),(5,"5 minutes before"),(10,"10 minutes before"),(15,"15 minutes before"),(30,"30 minutes before")]

    var body: some View {
        NavigationStack {
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
                    Spacer(minLength: 32)
                }
                .padding(.top, AppTheme.padding)
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
                        .foregroundStyle(action.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(action.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { focusedField = .action }
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

        var a = AttributedString(action.isEmpty ? "______" : action)
        a.foregroundColor = .orange
        a.underlineStyle = .single

        var comma = AttributedString(", ")
        comma.foregroundColor = .secondary

        var sched = AttributedString(scheduleText)
        sched.foregroundColor = .purple
        sched.underlineStyle = .single

        var become = AttributedString(" so that I can become ")
        become.foregroundColor = .secondary

        var id = AttributedString(identity.isEmpty ? "______" : identity)
        id.foregroundColor = .indigo
        id.underlineStyle = .single

        var period = AttributedString(".")
        period.foregroundColor = .secondary

        return s + a + comma + sched + become + id + period
    }

    // MARK: - Fields

    private var actionField: some View {
        inputSection(label: "I will…") {
            TextField("read 10 pages", text: $action)
                .focused($focusedField, equals: .action)
                .submitLabel(.next)
                .onSubmit { focusedField = .identity }
        }
    }

    private var identityField: some View {
        inputSection(label: "So I can become…") {
            TextField("a sharper, continuously learning person", text: $identity, axis: .vertical)
                .focused($focusedField, equals: .identity)
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
                    Button { if goalCount > 1 { goalCount -= 1 } } label: {
                        Image(systemName: "minus").frame(width: 32, height: 32)
                    }
                    Text("\(goalCount)")
                        .font(.system(.body, weight: .medium))
                        .frame(minWidth: 28)
                    Button { goalCount += 1 } label: {
                        Image(systemName: "plus").frame(width: 32, height: 32)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                Picker("", selection: $goalUnit) {
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

    // MARK: - Habit Time

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
                                Text(label)
                                    .foregroundStyle(.primary)
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

    private var scheduleText: String {
        let days = scheduleDays.sorted()
        let timeStr = habitTimeEnabled ? " at \(timeString)" : ""
        if days.count == 7 { return "every day\(timeStr)" }
        if Set(days) == Set([1,2,3,4,5]) { return "on weekdays\(timeStr)" }
        if Set(days) == Set([0,6]) { return "on weekends\(timeStr)" }
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return "on \(days.map { names[$0] }.joined(separator: ", "))\(timeStr)"
    }

    private var timeString: String {
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return fmt.string(from: habitTime)
    }

    private var repeatLabel: String {
        let days = scheduleDays
        if days.count == 7 { return "Daily" }
        if Set(days) == Set([1,2,3,4,5]) { return "Weekdays" }
        if Set(days) == Set([0,6]) { return "Weekends" }
        return "Custom"
    }

    private func save() {
        let trimmed = action.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let habit = Habit(name: trimmed, frequency: scheduleDays.count == 7 ? .daily : .weekly)
        habit.action = trimmed
        habit.identity = identity.trimmingCharacters(in: .whitespaces)
        habit.scheduleDays = scheduleDays.sorted()
        habit.goalCount = goalCount
        habit.goalUnit = goalUnit
        if habitTimeEnabled {
            habit.habitTimeInterval = habitTime.timeIntervalSince(Calendar.current.startOfDay(for: habitTime))
        }
        habit.reminderEnabled = reminderEnabled && habitTimeEnabled
        habit.reminderOffsetMinutes = reminderOffset
        modelContext.insert(habit)
        if habit.reminderEnabled {
            HabitNotificationManager.requestPermission()
            HabitNotificationManager.schedule(for: habit)
        }
        dismiss()
    }
}

#Preview {
    HabitCreationView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
