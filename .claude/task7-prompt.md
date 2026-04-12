You are implementing Task 7 of the LastApp iOS project: Task creation sheet.

## Context

Tasks 1-6 complete. TaskListView has a stub `TaskCreationView` at its bottom. Replace that stub with a real implementation in a new file.

**Design direction:**
- Sheet slides up. Starts in quick-add mode (compact).
- Quick mode: large title TextField (auto-focused), scrollable row of date shortcut chips (Today/Tomorrow/Next Week) + priority circles, Done button in toolbar
- Full mode: expands to large detent, reveals Notes field + List picker
- Expand toggle: chevron button in leading toolbar position
- Teal Done button (disabled/gray when title empty)
- Keyboard Done button dismisses and saves
- On empty title tap outside: dismiss without saving

**Key facts:**
- Xcode 16: files on disk are auto-included
- Simulator: 'iPhone 17 Pro'
- Git root: `/Users/jay/dev/last-app/`
- Source: `/Users/jay/dev/last-app/LastApp/LastApp/`
- Project: `/Users/jay/dev/last-app/LastApp/LastApp.xcodeproj`

## Files to create

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskCreationView.swift`

## Files to modify

- `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` — remove `struct TaskCreationView` stub at the bottom

## Step 1: Write TaskCreationView.swift

```swift
// LastApp/Features/Tasks/Views/TaskCreationView.swift
import SwiftUI
import SwiftData

struct TaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date? = nil
    @State private var priority: Priority = .p4
    @State private var selectedList: TaskList? = nil
    @State private var isExpanded = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Task name", text: $title, axis: .vertical)
                    .font(.system(.title3, weight: .medium))
                    .focused($titleFocused)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .submitLabel(.done)
                    .onSubmit { saveIfValid() }

                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        dateChip("Today", date: .now)
                        dateChip("Tomorrow", date: .tomorrow)
                        dateChip("Next Week", date: .nextWeek)

                        Divider().frame(height: 20)

                        ForEach(Priority.allCases.filter { $0 != .p4 }, id: \.self) { p in
                            priorityChip(p)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.vertical, 10)
                }

                if isExpanded {
                    Divider()
                    expandedFields
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { saveIfValid() }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { saveIfValid() }
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .presentationDetents(isExpanded ? [.large] : [.height(260)])
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
    }

    private var expandedFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Notes", text: $notes, axis: .vertical)
                .font(.system(.body))
                .foregroundStyle(.secondary)
                .padding(AppTheme.padding)

            if !customLists.isEmpty {
                Divider()
                Picker("List", selection: $selectedList) {
                    Text("Inbox").tag(nil as TaskList?)
                    ForEach(customLists) { list in
                        Label(list.name, systemImage: list.icon).tag(list as TaskList?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)
            }
        }
    }

    private func dateChip(_ label: String, date: Date) -> some View {
        let isSelected = dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            dueDate = isSelected ? nil : date
        } label: {
            Text(label)
                .font(.system(.caption, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.appAccent : Color.secondary.opacity(0.15)))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func priorityChip(_ p: Priority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = isSelected ? .p4 : p
        } label: {
            ZStack {
                Circle()
                    .fill(Color.priorityColor(p))
                    .frame(width: 28, height: 28)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveIfValid() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { dismiss(); return }
        let task = TaskItem(title: trimmed, notes: notes, dueDate: dueDate, priority: priority, list: selectedList)
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    TaskCreationView()
        .modelContainer(for: [TaskItem.self, TaskList.self], inMemory: true)
}
```

## Step 2: Remove TaskCreationView stub from TaskListView.swift

Open `/Users/jay/dev/last-app/LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` and remove the line:
```swift
struct TaskCreationView: View { var body: some View { Text("Create Task") } }
```

Keep the `TaskDetailView` stub.

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
cd /Users/jay/dev/last-app && git add LastApp/ && git commit -m "Task 7: Add TaskCreationView quick-add sheet"
```

## Report back with:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- Build/test results
- Files changed
- Any concerns
