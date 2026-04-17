# TickTick Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parse a TickTick CSV backup and import all folders, lists, tasks (including completed, subtasks, and checklist items) into LastApp, with duplicate skipping via `tickTickId`.

**Architecture:** A standalone `TickTickImporter` struct does all CSV parsing and SwiftData writes. A two-pass approach creates all tasks in pass 1, then wires parent-child subtask relationships in pass 2. `SettingsView` gets a new "Data" section with an async import button backed by `fileImporter`.

**Tech Stack:** SwiftUI, SwiftData, Foundation (ISO8601DateFormatter, NSRegularExpression), UniformTypeIdentifiers (.commaSeparatedText)

---

## File Map

**Create:**
- `LastApp/LastApp/Core/Settings/TickTickImporter.swift` — CSV parser, data mapper, SwiftData writer, `ImportResult`

**Modify:**
- `LastApp/LastApp/Features/Tasks/Models/TaskItem.swift` — add `var tickTickId: String? = nil`
- `LastApp/LastApp/Core/Settings/SettingsView.swift` — add "Data" section with import UI

---

## Task 1: Add `tickTickId` to TaskItem

**Files:**
- Modify: `LastApp/LastApp/Features/Tasks/Models/TaskItem.swift`

- [ ] **Step 1: Add `tickTickId` property**

Replace the entire file `LastApp/LastApp/Features/Tasks/Models/TaskItem.swift`:

```swift
// LastApp/Features/Tasks/Models/TaskItem.swift
import SwiftData
import Foundation

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date? = nil
    var priorityRaw: Int = Priority.p4.rawValue
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var sortOrder: Int = 0
    var tags: [String] = []
    var tickTickId: String? = nil

    @Relationship(deleteRule: .nullify) var list: TaskList?
    @Relationship(deleteRule: .cascade) var subtasks: [TaskItem] = []

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .p4 }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: Priority = .p4,
        list: TaskList? = nil
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.list = list
    }
}
```

- [ ] **Step 2: Build and verify**

Open Xcode, press Cmd+B. Expected: Build Succeeded. SwiftData automatically handles lightweight migration for the new optional property.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Tasks/Models/TaskItem.swift
git commit -m "feat(import): add tickTickId to TaskItem for deduplication"
```

---

## Task 2: Create TickTickImporter

**Files:**
- Create: `LastApp/LastApp/Core/Settings/TickTickImporter.swift`

- [ ] **Step 1: Create TickTickImporter.swift**

Create `LastApp/LastApp/Core/Settings/TickTickImporter.swift`:

```swift
// LastApp/Core/Settings/TickTickImporter.swift
import Foundation
import SwiftData

struct ImportResult {
    let foldersCreated: Int
    let listsCreated: Int
    let tasksCreated: Int
    let skipped: Int
}

struct TickTickImporter {

    func run(url: URL, context: ModelContext) async throws -> ImportResult {
        let text = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(text)

        // CSV structure:
        //   row 0: Date metadata
        //   row 1: Version metadata
        //   row 2: Status legend (multi-line quoted field)
        //   row 3: Column headers
        //   row 4+: Data
        guard rows.count > 4 else { throw ImportError.invalidFormat }
        let dataRows = Array(rows.dropFirst(4))

        // Build dedup set from existing TaskItems
        let existing = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let existingIds = Set(existing.compactMap(\.tickTickId))

        var foldersCreated = 0
        var listsCreated = 0
        var tasksCreated = 0
        var skipped = 0

        // Caches to avoid duplicate folder/list creation within this import
        var folderCache: [String: TaskFolder] = [:]
        var listCache: [String: TaskList] = [:]   // key: "FolderName///ListName"
        var taskMap: [String: TaskItem] = [:]      // key: TickTick taskId → TaskItem

        // MARK: Pass 1 — create all tasks

        for row in dataRows {
            guard row.count >= 24 else { continue }

            let folderName   = row[0]
            let listName     = row[1]
            let title        = row[2].trimmingCharacters(in: .whitespaces)
            let kind         = row[3]
            let tagsRaw      = row[4]
            let content      = row[5]
            let isChecklist  = row[6]
            let dueDateStr   = row[8]
            let priorityStr  = row[11]
            let statusStr    = row[12]
            let completedStr = row[14]
            let tickTickId   = row[22]
            let parentId     = row[23]

            guard !title.isEmpty else { continue }

            // Folder without list → no valid destination, skip
            if !folderName.isEmpty && listName.isEmpty { continue }

            // Dedup by tickTickId
            if !tickTickId.isEmpty && existingIds.contains(tickTickId) {
                skipped += 1
                continue
            }

            // Resolve or create TaskList (and TaskFolder if needed)
            var taskList: TaskList? = nil
            if !listName.isEmpty {
                let cacheKey = "\(folderName)///\(listName)"
                if let cached = listCache[cacheKey] {
                    taskList = cached
                } else {
                    var folder: TaskFolder? = nil
                    if !folderName.isEmpty {
                        if let cached = folderCache[folderName] {
                            folder = cached
                        } else {
                            let f = TaskFolder(name: folderName)
                            context.insert(f)
                            folderCache[folderName] = f
                            foldersCreated += 1
                            folder = f
                        }
                    }
                    let l = TaskList(name: listName)
                    l.folder = folder
                    context.insert(l)
                    listCache[cacheKey] = l
                    listsCreated += 1
                    taskList = l
                }
            }

            // Priority: TickTick 0=none, 1=low, 3=medium, 5=high → p4/p3/p2/p1
            let priority: Priority
            switch Int(priorityStr) ?? 0 {
            case 1:  priority = .p3
            case 3:  priority = .p2
            case 5:  priority = .p1
            default: priority = .p4
            }

            // Status: 0=active, 1=completed, 2=archived
            let statusVal = Int(statusStr) ?? 0
            let isCompleted = statusVal == 1 || statusVal == 2

            let task = TaskItem(
                title: title,
                notes: stripMarkdownImages(content),
                dueDate: parseDate(dueDateStr),
                priority: priority,
                list: taskList
            )
            task.isCompleted = isCompleted
            task.completedAt = parseDate(completedStr)
            task.tags = tagsRaw.isEmpty ? [] :
                tagsRaw.components(separatedBy: ", ")
                       .map { $0.trimmingCharacters(in: .whitespaces) }
                       .filter { !$0.isEmpty }
            task.tickTickId = tickTickId.isEmpty ? nil : tickTickId
            context.insert(task)

            if !tickTickId.isEmpty {
                taskMap[tickTickId] = task
            }

            // Parse checklist content into subtasks (only for top-level rows to avoid triple-nesting)
            if parentId.isEmpty && (kind == "CHECKLIST" || isChecklist == "Y") {
                for (itemTitle, itemCompleted) in parseChecklistItems(content) {
                    let sub = TaskItem(title: itemTitle, list: taskList)
                    sub.isCompleted = itemCompleted
                    context.insert(sub)
                    task.subtasks.append(sub)
                }
            }

            tasksCreated += 1
        }

        // MARK: Pass 2 — wire parentId subtask relationships

        for row in dataRows {
            guard row.count >= 24 else { continue }
            let tickTickId = row[22]
            let parentId   = row[23]
            guard !parentId.isEmpty, !tickTickId.isEmpty else { continue }
            if let child = taskMap[tickTickId], let parent = taskMap[parentId] {
                if !parent.subtasks.contains(where: { $0 === child }) {
                    parent.subtasks.append(child)
                }
            }
        }

        try context.save()

        return ImportResult(
            foldersCreated: foldersCreated,
            listsCreated: listsCreated,
            tasksCreated: tasksCreated,
            skipped: skipped
        )
    }

    // MARK: - CSV Parser (RFC 4180, handles quoted fields with embedded commas and newlines)

    private func parseCSV(_ input: String) -> [[String]] {
        var rows: [[String]] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var idx = input.startIndex

        while idx < input.endIndex {
            let ch = input[idx]
            let nextIdx = input.index(after: idx)

            if inQuotes {
                if ch == "\"" {
                    if nextIdx < input.endIndex && input[nextIdx] == "\"" {
                        // Escaped double-quote inside quoted field
                        field.append("\"")
                        idx = input.index(after: nextIdx)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else {
                switch ch {
                case "\"":
                    inQuotes = true
                case ",":
                    fields.append(field)
                    field = ""
                case "\r":
                    fields.append(field)
                    field = ""
                    rows.append(fields)
                    fields = []
                    // Consume \n in \r\n
                    if nextIdx < input.endIndex && input[nextIdx] == "\n" {
                        idx = input.index(after: nextIdx)
                        continue
                    }
                case "\n":
                    fields.append(field)
                    field = ""
                    rows.append(fields)
                    fields = []
                default:
                    field.append(ch)
                }
            }
            idx = input.index(after: idx)
        }

        // Handle final row
        fields.append(field)
        if !(fields.count == 1 && fields[0].isEmpty) {
            rows.append(fields)
        }

        return rows
    }

    // MARK: - Helpers

    private func parseDate(_ str: String) -> Date? {
        guard !str.isEmpty else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: str)
    }

    private func stripMarkdownImages(_ content: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"!\[image\]\([^)]+\)"#) else { return content }
        let range = NSRange(content.startIndex..., in: content)
        return regex.stringByReplacingMatches(in: content, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parses ▫ (U+25AB, unchecked) and ▪ (U+25AA, checked) delimited items from TickTick checklist content.
    private func parseChecklistItems(_ content: String) -> [(title: String, isCompleted: Bool)] {
        var items: [(String, Bool)] = []
        var current = ""
        var isChecked = false
        var started = false

        for scalar in content.unicodeScalars {
            if scalar.value == 0x25AB { // ▫ unchecked
                if started, !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    items.append((current.trimmingCharacters(in: .whitespacesAndNewlines), isChecked))
                }
                current = ""; isChecked = false; started = true
            } else if scalar.value == 0x25AA { // ▪ checked
                if started, !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    items.append((current.trimmingCharacters(in: .whitespacesAndNewlines), isChecked))
                }
                current = ""; isChecked = true; started = true
            } else if started {
                current.append(Character(scalar))
            }
        }

        if started, !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append((current.trimmingCharacters(in: .whitespacesAndNewlines), isChecked))
        }

        return items
    }

    enum ImportError: LocalizedError {
        case invalidFormat
        var errorDescription: String? {
            "Couldn't read file — make sure it's a TickTick backup CSV"
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Press Cmd+B. Expected: Build Succeeded with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Core/Settings/TickTickImporter.swift
git commit -m "feat(import): add TickTickImporter with CSV parser and SwiftData writer"
```

---

## Task 3: Add import UI to SettingsView

**Files:**
- Modify: `LastApp/LastApp/Core/Settings/SettingsView.swift`

- [ ] **Step 1: Replace SettingsView.swift with import UI added**

Replace the entire file `LastApp/LastApp/Core/Settings/SettingsView.swift`:

```swift
// LastApp/Core/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeatureConfig.sortOrder) private var featureConfigs: [FeatureConfig]
    @AppStorage("restTimerDuration") private var restTimerDuration: Int = 60
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday: Bool = false
    @AppStorage("showInbox") private var showInbox: Bool = true
    @AppStorage("showToday") private var showToday: Bool = true
    @AppStorage("showUpcoming") private var showUpcoming: Bool = true
    @AppStorage("showCompleted") private var showCompleted: Bool = true

    @State private var showingFilePicker = false
    @State private var importState: ImportState = .idle

    private let restTimerOptions = [30, 60, 90, 120, 180, 300]

    var body: some View {
        List {
            Section("Tasks") {
                Toggle("Show Inbox", isOn: $showInbox)
                Toggle("Show Today", isOn: $showToday)
                Toggle("Show Upcoming", isOn: $showUpcoming)
                Toggle("Show Completed", isOn: $showCompleted)
            }

            Section("Habits") {
                Picker("Week Starts On", selection: $weekStartsOnMonday) {
                    Text("Sunday").tag(false)
                    Text("Monday").tag(true)
                }
            }

            Section("Workout") {
                Picker("Rest Timer", selection: $restTimerDuration) {
                    ForEach(restTimerOptions, id: \.self) { seconds in
                        Text(restTimerLabel(seconds)).tag(seconds)
                    }
                }
                Picker("Weight Unit", selection: $weightUnit) {
                    Text("lbs").tag("lbs")
                    Text("kg").tag("kg")
                }
            }

            Section("Features") {
                ForEach(featureConfigs) { config in
                    if let definition = FeatureRegistry.definition(for: config.featureKey) {
                        FeatureToggleView(
                            definition: definition,
                            isEnabled: Binding(
                                get: { config.isEnabled },
                                set: { config.isEnabled = $0 }
                            )
                        )
                    }
                }
                .onMove { source, destination in
                    var reordered = featureConfigs
                    reordered.move(fromOffsets: source, toOffset: destination)
                    for (index, config) in reordered.enumerated() {
                        config.sortOrder = index
                    }
                    try? modelContext.save()
                }
            }

            Section("Data") {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Label("Import from TickTick", systemImage: "arrow.down.doc")
                            .foregroundStyle(.primary)
                        Spacer()
                        if case .importing = importState {
                            ProgressView()
                        }
                    }
                }
                .disabled({
                    if case .importing = importState { return true }
                    return false
                }())

                switch importState {
                case .success(let result):
                    Text("\(result.foldersCreated) folders · \(result.listsCreated) lists · \(result.tasksCreated) tasks imported, \(result.skipped) skipped")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .failure(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                default:
                    EmptyView()
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText]
            ) { result in
                switch result {
                case .success(let url):
                    let accessed = url.startAccessingSecurityScopedResource()
                    importState = .importing
                    Task {
                        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let importResult = try await TickTickImporter().run(url: url, context: modelContext)
                            importState = .success(importResult)
                        } catch {
                            importState = .failure(error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    importState = .failure(error.localizedDescription)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            EditButton()
        }
    }

    private func restTimerLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return secs == 0 ? "\(mins) min" : "\(mins)m \(secs)s"
    }

    private enum ImportState {
        case idle
        case importing
        case success(ImportResult)
        case failure(String)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [FeatureConfig.self], inMemory: true)
}
```

- [ ] **Step 2: Build and verify**

Press Cmd+B. Expected: Build Succeeded with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Core/Settings/SettingsView.swift
git commit -m "feat(import): add TickTick import UI to Settings Data section"
```

---

## Task 4: Manual verification

- [ ] **Step 1: Run on simulator**

Select an iPhone 15 simulator in Xcode and press Cmd+R.

- [ ] **Step 2: Navigate to Settings**

Open the sidebar and tap "Settings". Confirm the new "Data" section appears with "Import from TickTick".

- [ ] **Step 3: Import the CSV**

Tap "Import from TickTick". The system file picker opens. Navigate to your TickTick CSV file (e.g. in Dropbox or Files). Select it. Confirm:
- A spinner appears briefly while importing
- A green result line appears: `X folders · Y lists · Z tasks imported, 0 skipped`

- [ ] **Step 4: Verify data in app**

Navigate to tasks (Inbox or any list). Confirm:
- Your TickTick lists and folders appear in the sidebar
- Tasks have correct titles, notes, due dates, priorities, and tags
- Completed tasks show as completed
- Tasks with subtasks show child items

- [ ] **Step 5: Verify deduplication**

Tap "Import from TickTick" again with the same CSV. Confirm the result shows `0 tasks imported, Z skipped` — no duplicates created.

- [ ] **Step 6: Final commit**

```bash
git commit --allow-empty -m "feat(import): TickTick import complete and manually verified"
```
