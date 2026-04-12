You are implementing Task 8 of the LastApp iOS project: Task detail view.

## Context

Tasks 1-7 complete. TaskListView has a stub `TaskDetailView` at its bottom. Replace it.

**Design direction:**
- Full screen pushed via NavigationStack
- Title: large editable TextField at top
- Notes: multiline TextField below, secondary color
- Metadata section: due date (tappable → inline DatePicker), priority selector (4 colored circles), list picker
- Subtasks: flat list with completion circles + inline add field
- Toolbar: complete/uncomplete toggle (teal checkmark icon), ellipsis menu with Delete
- No excessive section headers — clean document feel

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskDetailView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` — remove `struct TaskDetailView` stub

## Step 1: Write TaskDetailView.swift

```swift
// LastApp/Features/Tasks/Views/TaskDetailView.swift
import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]

    @State private var newSubtaskTitle = ""
    @State private var showingDatePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                Divider().padding(.vertical, 4)
                notesSection
                Divider().padding(.vertical, 4)
                metadataSection
                Divider().padding(.vertical, 4)
                subtasksSection
            }
            .padding(.vertical, AppTheme.padding)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        task.isCompleted.toggle()
                        task.completedAt = task.isCompleted ? Date() : nil
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.isCompleted ? Color.appAccent : .secondary)
                        .font(.system(.title3))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var titleSection: some View {
        TextField("Task title", text: $task.title, axis: .vertical)
            .font(.system(.title2, weight: .semibold))
            .padding(.horizontal, AppTheme.padding)
            .padding(.bottom, 8)
    }

    private var notesSection: some View {
        TextField("Notes", text: $task.notes, axis: .vertical)
            .font(.system(.body))
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            // Due date row
            HStack {
                Label(
                    task.dueDate.map { $0.shortFormatted } ?? "No date",
                    systemImage: "calendar"
                )
                .foregroundStyle(task.dueDate == nil ? .secondary : .primary)
                Spacer()
                if task.dueDate != nil {
                    Button("Clear") { task.dueDate = nil }
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { showingDatePicker.toggle() }

            if showingDatePicker {
                DatePicker(
                    "Due date",
                    selection: Binding(
                        get: { task.dueDate ?? Date() },
                        set: { task.dueDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.appAccent)
                .padding(.horizontal, AppTheme.padding)
            }

            Divider().padding(.vertical, 4)

            // Priority
            HStack(spacing: 8) {
                Label("Priority", systemImage: "flag")
                    .foregroundStyle(.secondary)
                    .font(.system(.body))
                Spacer()
                ForEach(Priority.allCases, id: \.self) { p in
                    Button {
                        task.priority = task.priority == p ? .p4 : p
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.priorityColor(p))
                                .frame(width: 24, height: 24)
                            if task.priority == p {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)

            Divider().padding(.vertical, 4)

            // List picker
            Picker("List", selection: $task.list) {
                Label("Inbox", systemImage: "tray").tag(nil as TaskList?)
                ForEach(customLists) { list in
                    Label(list.name, systemImage: list.icon).tag(list as TaskList?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 8)
        }
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SUBTASKS")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppTheme.padding)
                .padding(.top, 12)

            ForEach(task.subtasks) { subtask in
                HStack(spacing: 12) {
                    Button {
                        subtask.isCompleted.toggle()
                    } label: {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(subtask.isCompleted ? Color.appAccent : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .strikethrough(subtask.isCompleted, color: .tertiary)
                        .foregroundStyle(subtask.isCompleted ? .tertiary : .primary)
                }
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 8)
            }

            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.appAccent)
                TextField("Add subtask", text: $newSubtaskTitle)
                    .font(.system(.body))
                    .onSubmit { addSubtask() }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 8)
        }
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let subtask = TaskItem(title: trimmed)
        modelContext.insert(subtask)
        task.subtasks.append(subtask)
        newSubtaskTitle = ""
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskItem.self, TaskList.self, configurations: config)
    let task = TaskItem(title: "Sample task", notes: "Some notes here", priority: .p2)
    container.mainContext.insert(task)
    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
}
```

## Step 2: Remove TaskDetailView stub from TaskListView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` and remove:
```swift
struct TaskDetailView: View { let task: TaskItem; var body: some View { Text(task.title) } }
```

## Step 3: Build

```bash
xcodebuild build \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | head -20
```

## Step 4: Run all tests

```bash
xcodebuild test \
  -project /Users/jay/dev/last-app/LastApp/LastApp.xcodeproj \
  -scheme LastApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|PASS|FAIL|error:|BUILD)" | head -40
```

## Step 5: Commit

```bash
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 8: Add TaskDetailView with inline editing, priority, subtasks"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
