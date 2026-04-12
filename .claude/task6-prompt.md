You are implementing Task 6 of the LastApp iOS project: TaskViewModel and TaskListView.

## Context

Tasks 1-5 complete. The sidebar drawer works. ContentView has stub views for TaskListView, TodayView, HabitListView, SettingsView at the bottom of ContentView.swift. You will replace the TaskListView stub with a real implementation.

**Design direction:**
- Task rows: completion circle (tap = done, teal fill + checkmark), title, priority dot (colored 8pt circle), due date chip (muted, red if overdue)
- Completed tasks: strikethrough title, tertiary color
- FAB: teal circle with + in bottom-right, teal shadow glow
- Empty state: icon + short message, centered, quaternary color
- List rows have no separators; clean flat list
- NavigationTitle changes per destination (Inbox, Today, Upcoming, etc.)
- Drag-to-reorder enabled with .onMove

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`
- The stub TaskListView, TodayView, HabitListView, SettingsView are defined at the bottom of ContentView.swift — you will remove TaskListView stub and replace with real file

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/ViewModels/TaskViewModel.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskListView.swift`
- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskRowView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` — remove the `struct TaskListView` stub (keep TodayView, HabitListView, SettingsView stubs)

## Step 1: Write TaskViewModel.swift

```swift
// LastApp/Features/Tasks/ViewModels/TaskViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class TaskViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addTask(title: String, notes: String = "", dueDate: Date? = nil, priority: Priority = .p4, list: TaskList? = nil) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, list: list)
        context.insert(task)
    }

    func toggleComplete(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
    }

    func delete(_ tasks: [TaskItem]) {
        tasks.forEach { context.delete($0) }
    }

    func updateSortOrder(_ tasks: [TaskItem]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }
}
```

## Step 2: Write TaskRowView.swift

```swift
// LastApp/Features/Tasks/Views/TaskRowView.swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.appAccent : Color.priorityColor(task.priority),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(.body))
                    .foregroundStyle(task.isCompleted ? .tertiary : .primary)
                    .strikethrough(task.isCompleted, color: .tertiary)
                    .lineLimit(2)

                if let due = task.dueDate, !task.isCompleted {
                    Text(due.shortFormatted)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(due < Date() ? .red : .secondary)
                }
            }

            Spacer()

            if task.priority != .p4 {
                Circle()
                    .fill(Color.priorityColor(task.priority))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
```

## Step 3: Write TaskListView.swift

```swift
// LastApp/Features/Tasks/Views/TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @State private var showingCreation = false

    private var viewModel: TaskViewModel {
        TaskViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreation) {
            TaskCreationView()
        }
    }

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(value: task) {
                    TaskRowView(task: task) {
                        withAnimation { viewModel.toggleComplete(task) }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                viewModel.delete(offsets.map { filteredTasks[$0] })
            }
            .onMove { from, to in
                var reordered = filteredTasks
                reordered.move(fromOffsets: from, toOffset: to)
                viewModel.updateSortOrder(reordered)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(emptyStateMessage)
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredTasks: [TaskItem] {
        let now = Date()
        switch appState.selectedDestination {
        case .inbox:
            return allTasks.filter { $0.list == nil && !$0.isCompleted }
        case .today:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 <= now.endOfDay } ?? false) }
        case .upcoming:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 > now.endOfDay } ?? false) }
        case .completed:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return allTasks.filter { $0.isCompleted && ($0.completedAt ?? Date.distantPast) >= thirtyDaysAgo }
        case .list(let id):
            return allTasks.filter { $0.list?.id == id && !$0.isCompleted }
        case .habits, .settings:
            return []
        }
    }

    private var navigationTitle: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .list(let id): allTasks.first { $0.list?.id == id }?.list?.name ?? "List"
        case .habits, .settings: ""
        }
    }

    private var emptyStateIcon: String {
        switch appState.selectedDestination {
        case .inbox: "tray"
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .completed: "checkmark.circle"
        default: "list.bullet"
        }
    }

    private var emptyStateMessage: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox zero"
        case .today: "Nothing due today"
        case .upcoming: "Nothing coming up"
        case .completed: "No completed tasks"
        default: "No tasks"
        }
    }
}

// Stubs for views implemented in later tasks
struct TaskCreationView: View { var body: some View { Text("Create Task") } }
struct TaskDetailView: View { let task: TaskItem; var body: some View { Text(task.title) } }
```

## Step 4: Remove TaskListView stub from ContentView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/LastApp/ContentView.swift` and remove the `struct TaskListView` stub at the bottom. Keep the other stubs (TodayView, HabitListView, SettingsView).

## Step 5: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

If errors about duplicate `TaskListView` — make sure the stub in ContentView.swift is fully removed.
If errors about missing `TaskCreationView` or `TaskDetailView` — they are stubbed at the bottom of TaskListView.swift.

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
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 6: Add TaskViewModel, TaskListView, TaskRowView"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
