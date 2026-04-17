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
        guard rows.count >= 4 else { throw ImportError.invalidFormat }
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

            // Folder name present but list name missing → skip (no list to assign to)
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

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let imageRegex = try! NSRegularExpression(pattern: #"!\[image\]\([^)]+\)"#)

    private func parseDate(_ str: String) -> Date? {
        guard !str.isEmpty else { return nil }
        return Self.iso8601.date(from: str)
    }

    private func stripMarkdownImages(_ content: String) -> String {
        let range = NSRange(content.startIndex..., in: content)
        return Self.imageRegex.stringByReplacingMatches(in: content, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parses ▫ (U+25AB, unchecked) and ▪ (U+25AA, checked) delimited items from TickTick checklist content.
    private func parseChecklistItems(_ content: String) -> [(title: String, isCompleted: Bool)] {
        var items: [(String, Bool)] = []
        var current = ""
        var isChecked = false
        var started = false

        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if started && !trimmed.isEmpty { items.append((trimmed, isChecked)) }
        }

        for scalar in content.unicodeScalars {
            if scalar.value == 0x25AB { // ▫ unchecked
                flush(); current = ""; isChecked = false; started = true
            } else if scalar.value == 0x25AA { // ▪ checked
                flush(); current = ""; isChecked = true; started = true
            } else if started {
                current.append(Character(scalar))
            }
        }
        flush()

        return items
    }

    enum ImportError: LocalizedError {
        case invalidFormat
        var errorDescription: String? {
            "Couldn't read file — make sure it's a TickTick backup CSV"
        }
    }
}
