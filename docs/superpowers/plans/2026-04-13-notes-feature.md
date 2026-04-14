# Notes Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full Notes feature with rich text editing (UITextView-based), notebook organization, tags, and pinning — accessible from the sidebar as a single "Notes" entry.

**Architecture:** A standalone feature following the existing plugin pattern (FeatureKey → FeatureDefinition → FeatureRegistry). Rich text is stored as archived NSAttributedString (`Data`) in a SwiftData `Note` model. A `UIViewRepresentable` wrapper (`RichTextEditor`) hosts a `UITextView`; a custom bottom toolbar applies formatting to selected text via NSAttributedString attributes. Notes are organized by `NoteNotebook` (optional, nullify on delete) and tags (String array on Note).

**Tech Stack:** SwiftUI, SwiftData, UIKit (`UITextView`, `NSAttributedString`, `UIViewRepresentable`), iOS 17+

---

## File Map

**Create:**
- `LastApp/LastApp/Features/Notes/NotesFeature.swift` — feature registration constant
- `LastApp/LastApp/Features/Notes/Models/Note.swift` — SwiftData model
- `LastApp/LastApp/Features/Notes/Models/NoteNotebook.swift` — SwiftData model
- `LastApp/LastApp/Features/Notes/Views/NoteListView.swift` — list with search, notebook chips, pinned grid, FAB
- `LastApp/LastApp/Features/Notes/Views/NoteEditorView.swift` — editor screen, auto-save, tag chips row, toolbar
- `LastApp/LastApp/Features/Notes/Views/RichTextEditor.swift` — UIViewRepresentable wrapping UITextView
- `LastApp/LastApp/Features/Notes/Views/NotebookManagerView.swift` — sheet for CRUD on notebooks

**Modify:**
- `LastApp/LastApp/Core/Features/FeatureKey.swift` — add `.notes`
- `LastApp/LastApp/Core/Navigation/SidebarDestination.swift` — add `case notes`
- `LastApp/LastApp/LastAppApp.swift` — register NotesFeature, add Note/NoteNotebook to schema
- `LastApp/LastApp/ContentView.swift` — add `.notes` case to `destinationView`, add Note/NoteNotebook to preview container
- `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` — add `.notes` to both exhaustive switches

---

## Task 1: Feature registration + SwiftData models

**Files:**
- Create: `LastApp/LastApp/Features/Notes/NotesFeature.swift`
- Create: `LastApp/LastApp/Features/Notes/Models/Note.swift`
- Create: `LastApp/LastApp/Features/Notes/Models/NoteNotebook.swift`
- Modify: `LastApp/LastApp/Core/Features/FeatureKey.swift`
- Modify: `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`
- Modify: `LastApp/LastApp/LastAppApp.swift`
- Modify: `LastApp/LastApp/ContentView.swift`
- Modify: `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift`

- [ ] **Step 1: Add `.notes` to FeatureKey**

Replace the entire file `LastApp/LastApp/Core/Features/FeatureKey.swift`:

```swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
    case workout = "workout"
    case cooking = "cooking"
    case notes = "notes"
}
```

- [ ] **Step 2: Add `case notes` to SidebarDestination**

Replace the entire file `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`:

```swift
// LastApp/Core/Navigation/SidebarDestination.swift
import Foundation

enum SidebarDestination: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case list(UUID)
    case habits
    case workout
    case cooking
    case notes
    case settings
}
```

- [ ] **Step 3: Create Note model**

Create `LastApp/LastApp/Features/Notes/Models/Note.swift`:

```swift
// LastApp/Features/Notes/Models/Note.swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    /// Archived NSAttributedString
    var bodyData: Data = Data()
    var isPinned: Bool = false
    var tags: [String] = []

    @Relationship(deleteRule: .nullify, inverse: \NoteNotebook.notes)
    var notebook: NoteNotebook?

    /// First non-empty line of plain text body, fallback "New Note"
    var title: String {
        guard let attr = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self, from: bodyData
        ) else { return "New Note" }
        let line = attr.string
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return line.map { String($0.prefix(80)) } ?? "New Note"
    }

    /// Second non-empty line (used as subtitle in list rows)
    var subtitle: String {
        guard let attr = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self, from: bodyData
        ) else { return "" }
        let lines = attr.string
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return "" }
        return String(lines[1].prefix(60))
    }

    init() {}
}
```

- [ ] **Step 4: Create NoteNotebook model**

Create `LastApp/LastApp/Features/Notes/Models/NoteNotebook.swift`:

```swift
// LastApp/Features/Notes/Models/NoteNotebook.swift
import Foundation
import SwiftData

@Model
final class NoteNotebook {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = ""
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify)
    var notes: [Note] = []

    init(name: String, colorHex: String = "", sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 5: Create NotesFeature registration**

Create `LastApp/LastApp/Features/Notes/NotesFeature.swift`:

```swift
// LastApp/Features/Notes/NotesFeature.swift
import SwiftUI

enum NotesFeature {
    static let definition = FeatureDefinition(
        key: .notes,
        displayName: "Notes",
        icon: "note.text",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Notes", systemImage: "note.text")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(NoteListView())
        }
    )
}
```

- [ ] **Step 6: Register in LastAppApp**

In `LastApp/LastApp/LastAppApp.swift`, add `Note.self, NoteNotebook.self` to the schema array and register `NotesFeature.definition` in `init()`.

The schema array (around line 10) should become:
```swift
let schema = Schema([
    TaskItem.self, TaskList.self, TaskFolder.self,
    Habit.self, HabitLog.self,
    FeatureConfig.self, FeatureLink.self,
    HabitStack.self, HabitStackEntry.self,
    Exercise.self, Routine.self, RoutineEntry.self,
    WorkoutSession.self, SessionExercise.self, SessionSet.self,
    Recipe.self, Ingredient.self, RecipeStep.self, RecipeCollection.self,
    Note.self, NoteNotebook.self
])
```

The `init()` body should become:
```swift
init() {
    FeatureRegistry.register(TasksFeature.definition)
    FeatureRegistry.register(HabitsFeature.definition)
    FeatureRegistry.register(WorkoutFeature.definition)
    FeatureRegistry.register(CookingFeature.definition)
    FeatureRegistry.register(NotesFeature.definition)
}
```

- [ ] **Step 7: Wire ContentView**

In `LastApp/LastApp/ContentView.swift`, add the `.notes` case to `destinationView`:

```swift
@ViewBuilder
private var destinationView: some View {
    switch appState.selectedDestination {
    case .inbox, .upcoming, .completed, .list:
        TaskListView()
    case .today:
        TodayView()
    case .habits:
        HabitListView()
    case .workout:
        WorkoutListView()
    case .cooking:
        RecipeListView()
    case .notes:
        NoteListView()
    case .settings:
        SettingsView()
    }
}
```

Also add `Note.self, NoteNotebook.self` to the `#Preview` model container array (line ~126).

- [ ] **Step 8: Fix exhaustive switches in TaskListView**

In `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift`, both `filteredTasks` and `navigationTitle` switches have a catch-all case like `case .habits, .workout, .cooking, .settings:`. Add `.notes` to both:

```swift
// filteredTasks
case .habits, .workout, .cooking, .notes, .settings:
    return []

// navigationTitle
case .habits, .workout, .cooking, .notes, .settings: ""
```

- [ ] **Step 9: Build and verify no compile errors**

Open Xcode, select the LastApp scheme, press Cmd+B. Expected: Build Succeeded with 0 errors. The app should launch and show a "Notes" row in the sidebar (since `NoteListView` doesn't exist yet, this step will fail — that's expected; the errors will be about missing `NoteListView`. Continue to Task 2).

Actually, since `NoteListView` is referenced in NotesFeature.swift and ContentView.swift, the build will fail. This is fine — proceed to Task 2 immediately.

- [ ] **Step 10: Commit**

```bash
git add LastApp/LastApp/Core/Features/FeatureKey.swift \
        LastApp/LastApp/Core/Navigation/SidebarDestination.swift \
        LastApp/LastApp/LastAppApp.swift \
        LastApp/LastApp/ContentView.swift \
        LastApp/LastApp/Features/Tasks/Views/TaskListView.swift \
        LastApp/LastApp/Features/Notes/
git commit -m "feat(notes): add models, feature registration, and navigation wiring"
```

---

## Task 2: RichTextEditor (UIViewRepresentable)

**Files:**
- Create: `LastApp/LastApp/Features/Notes/Views/RichTextEditor.swift`

This is the core UIKit bridge. Build it first so the editor view can depend on it.

- [ ] **Step 1: Create RichTextEditor.swift**

Create `LastApp/LastApp/Features/Notes/Views/RichTextEditor.swift`:

```swift
// LastApp/Features/Notes/Views/RichTextEditor.swift
import SwiftUI
import UIKit

/// UIViewRepresentable wrapping UITextView for rich text editing.
/// - `attributedText`: two-way binding to the NSAttributedString content
/// - `onTextChange`: called whenever text changes (for updating modifiedAt)
/// - `textViewRef`: exposes the underlying UITextView so the toolbar can call formatting helpers
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var onTextChange: () -> Void = {}
    var textViewRef: ((UITextView) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 17)
        tv.textColor = .label
        tv.delegate = context.coordinator
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 120, right: 4)
        tv.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.label
        ]
        textViewRef?(tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Only update if content actually changed to avoid cursor jumping
        if tv.attributedText != attributedText {
            let selected = tv.selectedRange
            tv.attributedText = attributedText
            tv.selectedRange = selected
        }
        textViewRef?(tv)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.onTextChange()
        }
    }
}

// MARK: - Formatting helpers (called by the toolbar)

extension UITextView {

    /// Toggle bold on the current selection (or typing attributes if no selection)
    func toggleBold() {
        applyFontTrait(.traitBold)
    }

    /// Toggle italic on the current selection
    func toggleItalic() {
        applyFontTrait(.traitItalic)
    }

    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        if selectedRange.length == 0 {
            // Toggle typing attributes
            let current = typingAttributes[.font] as? UIFont ?? .systemFont(ofSize: 17)
            typingAttributes[.font] = current.hasTrait(trait)
                ? current.withoutTrait(trait)
                : current.withTrait(trait)
        } else {
            textStorage.beginEditing()
            textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                let font = (value as? UIFont) ?? .systemFont(ofSize: 17)
                let newFont = font.hasTrait(trait) ? font.withoutTrait(trait) : font.withTrait(trait)
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
            textStorage.endEditing()
        }
    }

    /// Toggle heading style (larger bold font) on the entire current line
    func toggleHeading() {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let headingFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 17)
        textStorage.beginEditing()
        let currentFont = textStorage.attribute(.font, at: lineRange.location, effectiveRange: nil) as? UIFont
        let isHeading = currentFont.map { $0.pointSize >= 20 } ?? false
        textStorage.addAttribute(.font, value: isHeading ? bodyFont : headingFont, range: lineRange)
        textStorage.endEditing()
    }

    /// Toggle yellow highlight on the current selection
    func toggleHighlight() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let current = textStorage.attribute(.backgroundColor, at: selectedRange.location, effectiveRange: nil)
        if current != nil {
            textStorage.removeAttribute(.backgroundColor, range: selectedRange)
        } else {
            textStorage.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.4), range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Toggle strikethrough on the current selection
    func toggleStrikethrough() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let existing = textStorage.attribute(.strikethroughStyle, at: selectedRange.location, effectiveRange: nil) as? Int
        if existing != nil {
            textStorage.removeAttribute(.strikethroughStyle, range: selectedRange)
        } else {
            textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Toggle inline code style on the current selection
    func toggleCode() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let existing = textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
        let isCode = existing?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) ?? false
        let newFont: UIFont = isCode
            ? .systemFont(ofSize: 17)
            : .monospacedSystemFont(ofSize: 15, weight: .regular)
        let bgColor: UIColor? = isCode ? nil : UIColor.systemGray5
        textStorage.addAttribute(.font, value: newFont, range: selectedRange)
        if let bg = bgColor {
            textStorage.addAttribute(.backgroundColor, value: bg, range: selectedRange)
        } else {
            textStorage.removeAttribute(.backgroundColor, range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Insert "• " at the start of the current line
    func insertBullet() {
        insertLinePrefix("• ")
    }

    /// Insert a numbered prefix at the start of the current line
    func insertNumberedItem() {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let linesBefore = (text as NSString).substring(to: lineRange.location)
        let count = linesBefore.components(separatedBy: "\n").filter { $0.hasPrefix("•") == false && $0.first?.isNumber == true }.count + 1
        insertLinePrefix("\(count). ")
    }

    /// Insert "☐ " at the start of the current line
    func insertCheckbox() {
        insertLinePrefix("☐ ")
    }

    private func insertLinePrefix(_ prefix: String) {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let lineStart = NSRange(location: lineRange.location, length: 0)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: lineStart, with: prefix)
        textStorage.endEditing()
        // Advance cursor
        selectedRange = NSRange(location: selectedRange.location + prefix.count, length: selectedRange.length)
    }

    /// Insert a horizontal rule at the current line
    func insertDivider() {
        let divider = "\n\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\n"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.separator
        ]
        let attrDivider = NSAttributedString(string: divider, attributes: attrs)
        textStorage.beginEditing()
        textStorage.insert(attrDivider, at: selectedRange.location)
        textStorage.endEditing()
        selectedRange = NSRange(location: selectedRange.location + divider.count, length: 0)
    }

    /// Apply/remove a link on the current selection
    func applyLink(_ urlString: String) {
        guard selectedRange.length > 0, let url = URL(string: urlString) else { return }
        textStorage.beginEditing()
        textStorage.addAttribute(.link, value: url, range: selectedRange)
        textStorage.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: selectedRange)
        textStorage.endEditing()
    }

    func removeLink() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        textStorage.removeAttribute(.link, range: selectedRange)
        textStorage.removeAttribute(.foregroundColor, range: selectedRange)
        textStorage.endEditing()
    }

    var cursorIsInLink: Bool {
        guard selectedRange.location < textStorage.length else { return false }
        return textStorage.attribute(.link, at: selectedRange.location, effectiveRange: nil) != nil
    }
}

// MARK: - UIFont helpers

private extension UIFont {
    func hasTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        fontDescriptor.symbolicTraits.contains(trait)
    }

    func withTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(trait)) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }

    func withoutTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.subtracting(trait)) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }
}
```

- [ ] **Step 2: Build and verify**

Press Cmd+B in Xcode. Expected: Build Succeeded (or only fails on NoteListView/NoteEditorView which don't exist yet — that's fine).

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Notes/Views/RichTextEditor.swift
git commit -m "feat(notes): add RichTextEditor UIViewRepresentable with formatting helpers"
```

---

## Task 3: NoteEditorView

**Files:**
- Create: `LastApp/LastApp/Features/Notes/Views/NoteEditorView.swift`

- [ ] **Step 1: Create NoteEditorView.swift**

Create `LastApp/LastApp/Features/Notes/Views/NoteEditorView.swift`:

```swift
// LastApp/Features/Notes/Views/NoteEditorView.swift
import SwiftUI
import SwiftData
import UIKit

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: Note

    @State private var attributedText: NSAttributedString = NSAttributedString()
    @State private var showPanel2 = false
    @State private var newTag = ""
    @State private var showingTagInput = false
    @State private var showingLinkAlert = false
    @State private var linkURL = ""
    @State private var textViewRef: UITextView? = nil

    var body: some View {
        ScrollView {
            RichTextEditor(
                attributedText: $attributedText,
                onTextChange: { /* modifiedAt updated on save */ },
                textViewRef: { tv in textViewRef = tv }
            )
            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 200)
            .padding(.horizontal, AppTheme.padding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                tagRow
                Divider()
                toolbar
            }
            .background(.regularMaterial)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadBody() }
        .onDisappear { save() }
        .alert("Add Link", isPresented: $showingLinkAlert) {
            TextField("https://", text: $linkURL)
            Button("Add") { textViewRef?.applyLink(linkURL); linkURL = "" }
            Button("Cancel", role: .cancel) { linkURL = "" }
        }
    }

    // MARK: - Tag Row

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(note.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.system(.caption, weight: .medium))
                        Button {
                            note.tags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appAccent.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.appAccent)
                }

                if showingTagInput {
                    TextField("tag", text: $newTag)
                        .font(.system(.caption))
                        .frame(width: 80)
                        .onSubmit {
                            let t = newTag.trimmingCharacters(in: .whitespaces).lowercased()
                            if !t.isEmpty && !note.tags.contains(t) { note.tags.append(t) }
                            newTag = ""
                            showingTagInput = false
                        }
                } else {
                    Button {
                        showingTagInput = true
                    } label: {
                        Label("Tag", systemImage: "plus")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 0) {
            if !showPanel2 {
                panel1
            } else {
                panel2
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
    }

    private var panel1: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "bold") { textViewRef?.toggleBold() }
            toolbarButton(icon: "italic") { textViewRef?.toggleItalic() }
            toolbarButton(icon: "highlighter") { textViewRef?.toggleHighlight() }
            toolbarButton(icon: "h.square") { textViewRef?.toggleHeading() }
            toolbarButton(icon: "checklist") { textViewRef?.insertCheckbox() }
            toolbarButton(icon: "list.bullet") { textViewRef?.insertBullet() }
            toolbarButton(icon: "list.number") { textViewRef?.insertNumberedItem() }
            Spacer()
            toolbarButton(icon: "chevron.right") { showPanel2 = true }
        }
    }

    private var panel2: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "chevron.left") { showPanel2 = false }
            toolbarButton(icon: "strikethrough") { textViewRef?.toggleStrikethrough() }
            toolbarButton(icon: "minus") { textViewRef?.insertDivider() }
            toolbarButton(icon: "link") { showingLinkAlert = true }
            if textViewRef?.cursorIsInLink == true {
                toolbarButton(icon: "link.badge.minus") { textViewRef?.removeLink() }
            }
            toolbarButton(icon: "chevron.left.forwardslash.chevron.right") { textViewRef?.toggleCode() }
            Spacer()
        }
    }

    private func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Persistence

    private func loadBody() {
        guard !note.bodyData.isEmpty else { return }
        if let attr = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: note.bodyData) {
            attributedText = attr
        }
    }

    private func save() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false) {
            note.bodyData = data
        }
        note.modifiedAt = Date()
        try? modelContext.save()
    }
}
```

- [ ] **Step 2: Build and verify**

Press Cmd+B. Expected: Build Succeeded (or only fails on NoteListView).

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Notes/Views/NoteEditorView.swift
git commit -m "feat(notes): add NoteEditorView with rich text toolbar and tag chips"
```

---

## Task 4: NotebookManagerView

**Files:**
- Create: `LastApp/LastApp/Features/Notes/Views/NotebookManagerView.swift`

- [ ] **Step 1: Create NotebookManagerView.swift**

Create `LastApp/LastApp/Features/Notes/Views/NotebookManagerView.swift`:

```swift
// LastApp/Features/Notes/Views/NotebookManagerView.swift
import SwiftUI
import SwiftData

struct NotebookManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteNotebook.sortOrder) private var notebooks: [NoteNotebook]

    @State private var showingAdd = false
    @State private var editingNotebook: NoteNotebook? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(notebooks) { nb in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(nb.colorHex.isEmpty ? Color.secondary.opacity(0.4) : Color(hex: nb.colorHex))
                            .frame(width: 12, height: 12)
                        Text(nb.name)
                        Spacer()
                        Text("\(nb.notes.count)")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                        Button { editingNotebook = nb } label: {
                            Image(systemName: "pencil")
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    offsets.map { notebooks[$0] }.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                }
            }
            .navigationTitle("Notebooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { NotebookFormView() }
            .sheet(item: $editingNotebook) { NotebookFormView(existing: $0) }
        }
    }
}

struct NotebookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteNotebook.sortOrder) private var notebooks: [NoteNotebook]

    var existing: NoteNotebook? = nil

    @State private var name = ""
    @State private var selectedColorHex = ""
    @State private var customColor: Color = Color(red: 0.4, green: 0.6, blue: 1.0)

    private let presetColors: [(hex: String, color: Color)] = [
        ("ef4444", Color(red: 0.937, green: 0.267, blue: 0.267)),
        ("f97316", Color(red: 0.957, green: 0.451, blue: 0.086)),
        ("eab308", Color(red: 0.918, green: 0.702, blue: 0.031)),
        ("84cc16", Color(red: 0.518, green: 0.800, blue: 0.086)),
        ("22c55e", Color(red: 0.133, green: 0.773, blue: 0.369)),
        ("3b82f6", Color(red: 0.231, green: 0.510, blue: 0.965)),
    ]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    TextField("Notebook name", text: $name)
                }
                .padding(AppTheme.padding)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                // Color picker
                HStack(spacing: 10) {
                    Button { selectedColorHex = "" } label: {
                        colorCircle(color: Color.secondary.opacity(0.25), isSelected: selectedColorHex == "", isNone: true)
                    }.buttonStyle(.plain)

                    ForEach(presetColors, id: \.hex) { preset in
                        Button { selectedColorHex = preset.hex } label: {
                            colorCircle(color: preset.color, isSelected: selectedColorHex == preset.hex)
                        }.buttonStyle(.plain)
                    }

                    ZStack {
                        ColorPicker(selection: $customColor, supportsOpacity: false) {
                            colorCircle(color: .clear, isSelected: selectedColorHex == "custom", isRainbow: true)
                        }
                        .labelsHidden()
                        .frame(width: 42, height: 42)
                    }
                    .onChange(of: customColor) { _, _ in selectedColorHex = "custom" }
                }

                Spacer()
            }
            .padding(AppTheme.padding)
            .navigationTitle(existing == nil ? "New Notebook" : "Edit Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let nb = existing {
                name = nb.name
                selectedColorHex = nb.colorHex
            }
        }
    }

    private func colorCircle(color: Color, isSelected: Bool, isNone: Bool = false, isRainbow: Bool = false) -> some View {
        ZStack {
            if isRainbow {
                Circle().fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center)).frame(width: 36, height: 36)
            } else {
                Circle().fill(color).frame(width: 36, height: 36)
            }
            if isNone { Image(systemName: "line.diagonal").font(.system(size: 18, weight: .medium)).foregroundStyle(.secondary).rotationEffect(.degrees(45)) }
            if isSelected { Circle().strokeBorder(Color.appAccent, lineWidth: 2.5).frame(width: 43, height: 43) }
        }
        .frame(width: 43, height: 43)
    }

    private func resolvedHex() -> String {
        if selectedColorHex == "custom" {
            let ui = UIColor(customColor)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: nil)
            return String(format: "%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
        }
        return selectedColorHex
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let hex = resolvedHex()
        if let nb = existing {
            nb.name = trimmed
            nb.colorHex = hex
        } else {
            let maxOrder = notebooks.map(\.sortOrder).max() ?? -1
            let nb = NoteNotebook(name: trimmed, colorHex: hex, sortOrder: maxOrder + 1)
            modelContext.insert(nb)
        }
        try? modelContext.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Build and verify**

Press Cmd+B. Expected: Build Succeeded (still may fail on NoteListView).

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Notes/Views/NotebookManagerView.swift
git commit -m "feat(notes): add NotebookManagerView and NotebookFormView"
```

---

## Task 5: NoteListView

**Files:**
- Create: `LastApp/LastApp/Features/Notes/Views/NoteListView.swift`

- [ ] **Step 1: Create NoteListView.swift**

Create `LastApp/LastApp/Features/Notes/Views/NoteListView.swift`:

```swift
// LastApp/Features/Notes/Views/NoteListView.swift
import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.modifiedAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: \NoteNotebook.sortOrder) private var notebooks: [NoteNotebook]

    @State private var searchText = ""
    @State private var selectedNotebook: NoteNotebook? = nil
    @State private var selectedNote: Note? = nil
    @State private var showingNotebooks = false

    private var filteredNotes: [Note] {
        allNotes.filter { note in
            let matchesNotebook: Bool = {
                guard let nb = selectedNotebook else { return true }
                return note.notebook?.id == nb.id
            }()
            let matchesSearch: Bool = {
                guard !searchText.isEmpty else { return true }
                let q = searchText.lowercased()
                let bodyText = (try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: note.bodyData))?.string.lowercased() ?? ""
                return bodyText.contains(q) || note.tags.contains(where: { $0.contains(q) })
            }()
            return matchesNotebook && matchesSearch
        }
    }

    private var pinnedNotes: [Note] { filteredNotes.filter { $0.isPinned } }
    private var unpinnedNotes: [Note] { filteredNotes.filter { !$0.isPinned } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search notes", text: $searchText)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, AppTheme.padding)
                .padding(.top, 8)

                // Notebook chips
                if !notebooks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            notebookChip(label: "All", color: nil, isSelected: selectedNotebook == nil) {
                                selectedNotebook = nil
                            }
                            ForEach(notebooks) { nb in
                                notebookChip(
                                    label: nb.name,
                                    color: nb.colorHex.isEmpty ? nil : Color(hex: nb.colorHex),
                                    isSelected: selectedNotebook?.id == nb.id
                                ) { selectedNotebook = nb }
                            }
                        }
                        .padding(.horizontal, AppTheme.padding)
                        .padding(.vertical, 10)
                    }
                }

                // Notes list
                if filteredNotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text("No notes yet")
                            .font(.system(.subheadline))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !pinnedNotes.isEmpty {
                            Section("Pinned") {
                                ForEach(pinnedNotes) { note in
                                    noteRow(note)
                                }
                            }
                        }

                        if !unpinnedNotes.isEmpty {
                            Section(pinnedNotes.isEmpty ? "" : "Notes") {
                                ForEach(unpinnedNotes) { note in
                                    noteRow(note)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }

            // FAB
            Button {
                let note = Note()
                modelContext.insert(note)
                if let nb = selectedNotebook { note.notebook = nb }
                try? modelContext.save()
                selectedNote = note
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
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingNotebooks = true } label: {
                    Image(systemName: "folder")
                }
            }
        }
        .navigationDestination(item: $selectedNote) { note in
            NoteEditorView(note: note)
        }
        .sheet(isPresented: $showingNotebooks) {
            NotebookManagerView()
        }
    }

    private func noteRow(_ note: Note) -> some View {
        Button { selectedNote = note } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !note.subtitle.isEmpty {
                    Text(note.subtitle)
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    Text(note.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(.caption2))
                        .foregroundStyle(.tertiary)
                    if let nb = note.notebook {
                        Text(nb.name)
                            .font(.system(.caption2))
                            .foregroundStyle(nb.colorHex.isEmpty ? .tertiary : Color(hex: nb.colorHex))
                    }
                    ForEach(note.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(.caption2))
                            .foregroundStyle(Color.appAccent.opacity(0.8))
                    }
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: AppTheme.padding, bottom: 8, trailing: AppTheme.padding))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .leading) {
            Button {
                note.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(Color.appAccent)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(note)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func notebookChip(label: String, color: Color?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let c = color {
                    Circle().fill(c).frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.system(.subheadline, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.appAccent.opacity(0.12) : Color.secondary.opacity(0.08),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.appAccent : .primary)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build and verify — full build should now succeed**

Press Cmd+B. Expected: **Build Succeeded** with 0 errors. All views and models are now in place.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Notes/Views/NoteListView.swift
git commit -m "feat(notes): add NoteListView with search, notebook chips, pinned section, and FAB"
```

---

## Task 6: Manual verification

No automated tests are available for SwiftUI apps in this project. Verify the feature manually.

- [ ] **Step 1: Run app on simulator**

In Xcode, select an iPhone 15 simulator and press Cmd+R.

- [ ] **Step 2: Verify sidebar**

Open the sidebar (swipe right from left edge or tap the hamburger icon). Confirm "Notes" appears as a row in the features section below Cooking.

- [ ] **Step 3: Verify note creation**

Tap "Notes". Tap the teal `+` FAB. Confirm a new blank `NoteEditorView` opens. Type some text — the first line should become the note title. Tap back. Confirm the note appears in the list with the correct title and subtitle.

- [ ] **Step 4: Verify rich text toolbar**

Open a note. Tap a word. Use the toolbar: Bold (`B`), Italic, Highlight, Heading (`H`). Confirm the text changes visually. Tap `›` to open panel 2. Try Strikethrough, Code, Divider. Tap `‹` to go back.

- [ ] **Step 5: Verify tags**

In the editor, tap the `+ Tag` button in the tag row. Type a tag name and press Return. Confirm the tag chip appears. Tap `×` on the chip to remove it.

- [ ] **Step 6: Verify notebooks**

Tap the folder icon in the Notes toolbar. Create a notebook named "Work" with a color. Dismiss the sheet. Confirm the "Work" chip appears below the search bar. Tap the `+` FAB while "Work" is selected — the new note should auto-assign to "Work".

- [ ] **Step 7: Verify pinning**

In the notes list, swipe a note right. Tap "Pin". Confirm it moves to the "Pinned" section. Swipe again and tap "Unpin" to confirm it returns.

- [ ] **Step 8: Verify search**

Type a word in the search bar. Confirm the list filters to notes containing that word.

- [ ] **Step 9: Final commit**

```bash
git commit --allow-empty -m "feat(notes): Notes feature complete and manually verified"
```
