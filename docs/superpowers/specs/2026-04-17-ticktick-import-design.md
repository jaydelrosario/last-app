# TickTick Import — Design Spec
_Date: 2026-04-17_

## Overview

Add a "Import from TickTick" feature to LastApp that parses a TickTick CSV backup and populates TaskFolders, TaskLists, and TaskItems — including subtasks and completed tasks. Entry point is a new Settings screen; the import service is designed to be callable from onboarding later.

---

## Decisions

| Decision | Choice |
|---|---|
| Entry point | Settings screen (new `SettingsView`) |
| Future onboarding | `TickTickImporter` is standalone — onboarding calls same method |
| Duplicate handling | Skip by `tickTickId` (store TickTick's `taskId` on `TaskItem`) |
| Import UX | Async with inline spinner → result card (no preview step) |
| Checklist items | Parse `▫`/`▪`-delimited content into real subtasks |
| CSV parsing | Native Swift (no third-party dependencies) |

---

## Architecture

### Files to Create

- `LastApp/LastApp/Features/Settings/SettingsView.swift` — grouped settings list with "Data" section
- `LastApp/LastApp/Features/Settings/TickTickImporter.swift` — async import service + `ImportResult`

### Files to Modify

- `LastApp/LastApp/Features/Tasks/Models/TaskItem.swift` — add `var tickTickId: String? = nil`
- `LastApp/LastApp/ContentView.swift` — wire `.settings` destination to `SettingsView`

### TickTickImporter API

```swift
struct ImportResult {
    let foldersCreated: Int
    let listsCreated: Int
    let tasksCreated: Int
    let skipped: Int  // duplicates by tickTickId
}

struct TickTickImporter {
    func run(url: URL, context: ModelContext) async throws -> ImportResult
}
```

The importer uses a **two-pass** approach:
1. **Pass 1** — insert all top-level tasks (no `parentId`)
2. **Pass 2** — wire subtasks (rows with `parentId`) and parse checklist items

---

## Data Mapping

| TickTick CSV column | LastApp field |
|---|---|
| `Folder Name` | `TaskFolder.name` (create if not exists) |
| `List Name` | `TaskList.name` (create if not exists, assigned to folder) |
| `Title` | `TaskItem.title` |
| `Content` | `TaskItem.notes` (plain text; markdown image refs stripped) |
| `Tags` | `TaskItem.tags` (comma-split → `[String]`) |
| `Due Date` | `TaskItem.dueDate` (ISO 8601 parse) |
| `Priority` 0 → p4, 1 → p3, 3 → p2, 5 → p1 | `TaskItem.priority` |
| `Status` 0 → active, 1 or 2 → completed | `TaskItem.isCompleted` |
| `Completed Time` | `TaskItem.completedAt` |
| `taskId` | `TaskItem.tickTickId` (dedup key) |
| `parentId` non-empty | wire as subtask of parent task |
| `Kind: CHECKLIST` + `▫`/`▪` content | parse into child `TaskItem` subtasks |

### Priority mapping

TickTick's priority values: `0` = none, `1` = low, `3` = medium, `5` = high

Maps to LastApp: `0→p4`, `1→p3`, `3→p2`, `5→p1`

### Checklist parsing

Tasks with `Kind = CHECKLIST` have content like `▫Item one▫Item two▪Completed item`.

- `▫` prefix → subtask with `isCompleted = false`
- `▪` prefix → subtask with `isCompleted = true`
- Each delimited segment becomes a separate `TaskItem` child

### Edge cases

- Empty `Title` → row skipped entirely
- `parentId` references a task not yet inserted → resolved in pass 2 using in-memory `taskId → TaskItem` map
- `Folder Name` empty + `List Name` non-empty → list created with no folder (top-level)
- `Folder Name` non-empty + `List Name` empty → row skipped (no list to assign to)
- `Folder Name` empty + `List Name` empty → task placed in Inbox (no list)
- Duplicate `taskId` already in SwiftData → skip, increment `skipped` counter

---

## UI Flow

### SettingsView

Grouped `List` with sections. Initial state:

```
Data
  └─ Import from TickTick   [arrow.down.doc icon]
```

### Import interaction

1. Tap row → `UIDocumentPickerViewController` opens, filtered to `.csv`
2. User picks file → picker dismisses
3. Row shows inline spinner + "Importing…" label
4. **Success** → green result card below row:
   `"3 folders · 12 lists · 247 tasks imported, 18 skipped"`
5. **Failure** → red inline message:
   `"Couldn't read file — make sure it's a TickTick backup CSV"`
6. Result/error stays visible until user navigates away

---

## Model Change

Add to `TaskItem.swift`:

```swift
var tickTickId: String? = nil
```

SwiftData handles the lightweight migration automatically for this new optional property.

---

## Future: Onboarding Hook

The onboarding screen can call `TickTickImporter().run(url:context:)` directly — same method, no changes needed to the importer itself.
