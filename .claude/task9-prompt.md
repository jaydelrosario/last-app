You are implementing Task 9 of the LastApp iOS project: HabitViewModel and HabitListView.

## Context

Tasks 1-8 complete. ContentView has a stub `HabitListView` at the bottom. Replace it.

**Design direction:**
- HabitListView: list of habits with today check-off
- Each row: completion circle (teal fill when done), habit name, frequency badge (tiny), streak (flame emoji + number in teal)
- Completed habits: circle full teal, name secondary color
- FAB: same teal + circle pattern as TaskListView
- Empty state: flame emoji + "Start your first habit"
- Tone: calm momentum — not gamified, not clinical

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/ViewModels/HabitViewModel.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitListView.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Habits/Views/HabitRowView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` — remove `struct HabitListView` stub

## Step 1: Write HabitViewModel.swift

```swift
// LastApp/Features/Habits/ViewModels/HabitViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class HabitViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addHabit(name: String, frequency: Frequency) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(name: name, frequency: frequency)
        context.insert(habit)
    }

    func toggleToday(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = habit.logs.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isCompleted.toggle()
        } else {
            let log = HabitLog(date: Date(), isCompleted: true, habit: habit)
            context.insert(log)
        }
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
    }
}
```

## Step 2: Write HabitRowView.swift

```swift
// LastApp/Features/Habits/Views/HabitRowView.swift
import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? Color.appAccent : Color.clear)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(
                            habit.isCompletedToday ? Color.appAccent : Color.secondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 28, height: 28)
                    if habit.isCompletedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(.body))
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
                Text(habit.frequency.rawValue)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if habit.streak > 0 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(.caption))
                    Text("\(habit.streak)")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
```

## Step 3: Write HabitListView.swift

```swift
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
```

## Step 4: Remove HabitListView stub from ContentView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` and remove:
```swift
struct HabitListView: View { var body: some View { Text("Habits").navigationTitle("Habits") } }
```

Keep the TodayView and SettingsView stubs.

## Step 5: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

## Step 6: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

## Step 7: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 9: Add HabitViewModel, HabitListView, HabitRowView"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
