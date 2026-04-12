You are implementing Task 10 of the LastApp iOS project: Habit creation and detail views.

## Context

Tasks 1-9 complete. HabitListView has stubs for HabitCreationView and HabitDetailView at the bottom. Replace them.

**Design direction:**
- HabitCreationView: minimal sheet — name field (auto-focused) + segmented frequency picker. Small detent (280pt).
- HabitDetailView: editable name at top, frequency picker, stats row (streak + created date), 30-day calendar grid
- Calendar grid: 7 columns, last 30 days, filled teal circles = completed, empty gray = missed, today has teal border ring
- Grid aligns to weekday columns (Sunday first) — pad leading empty cells
- Tone: calm, not gamified

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitCreationView.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitDetailView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitListView.swift` — remove stubs for HabitCreationView and HabitDetailView

## Step 1: Write HabitCreationView.swift

```swift
// LastApp/Features/Habits/Views/HabitCreationView.swift
import SwiftUI

struct HabitCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var frequency: Frequency = .daily
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit name", text: $name)
                        .focused($nameFocused)
                        .font(.system(.body))
                }

                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
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
                        .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { nameFocused = true }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let habit = Habit(name: trimmed, frequency: frequency)
        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    HabitCreationView()
        .modelContainer(for: Habit.self, inMemory: true)
}
```

## Step 2: Write HabitDetailView.swift

```swift
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
```

## Step 3: Remove stubs from HabitListView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitListView.swift` and remove:
```swift
struct HabitCreationView: View { var body: some View { Text("Create Habit") } }
struct HabitDetailView: View { let habit: Habit; var body: some View { Text(habit.name) } }
```

## Step 4: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

## Step 5: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

## Step 6: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 10: Add HabitCreationView and HabitDetailView with 30-day calendar grid"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
