# Notes Feature Design

## Overview

A standalone Notes feature accessible from the sidebar. Supports rich text editing (UITextView-based), notebook organization, tags, and pinning. Title-optional — the first non-empty line of content becomes the note's title, like Apple Notes.

---

## Data Models

### `Note`
- `id: UUID`
- `createdAt: Date`
- `modifiedAt: Date`
- `bodyData: Data` — archived `NSAttributedString`
- `isPinned: Bool` (default `false`)
- `tags: [String]` (default `[]`)
- `notebook: NoteNotebook?` — nullify on delete

**Derived (not stored):** `title: String` — first non-empty line of `bodyData`'s plain text, fallback `"New Note"`

### `NoteNotebook`
- `id: UUID`
- `name: String`
- `colorHex: String` (default `""`)
- `sortOrder: Int`
- `notes: [Note]` — inverse of `Note.notebook`, nullify delete rule

Tags are stored as `[String]` directly on `Note`. No separate Tag model.

---

## Navigation

- Sidebar: `.notes` destination → `NoteListView`
- `NoteListView` → push `NoteEditorView` for create/edit
- `NoteListView` toolbar → sheet `NotebookManagerView`

---

## Views

### `NoteListView`
- Search bar (filters by title/body plain text)
- Horizontal notebook filter chips: "All" + one chip per notebook, colored dot
- **Pinned** section (shown only when ≥1 pinned note): 2-column grid of note cards
- **Notes** section: list rows sorted by `modifiedAt` descending
- Note row: derived title (bold), first line of body as subtitle (1 line, secondary), relative date
- Swipe leading: pin/unpin (`pin` / `pin.slash` icon)
- Swipe trailing: delete (destructive)
- FAB (bottom-right `+`): creates a new `Note`, immediately navigates to `NoteEditorView`
- Toolbar trailing: "Notebooks" button → sheet `NotebookManagerView`
- Empty state: icon + "No notes yet" message

### `NoteEditorView`
- Navigation back button auto-saves (calls `save()` on `onDisappear`)
- No title field — first line of `UITextView` content is the title
- `RichTextEditor` fills the screen inside a `ScrollView`
- Tag chip row above the bottom toolbar: existing tags as dismissible chips, `+` button to type and add a new tag
- Bottom formatting toolbar (two panels, full-width, above keyboard)
- `modifiedAt` updated on every save

### `RichTextEditor` (UIViewRepresentable)
Wraps `UITextView`:
- `isScrollEnabled = false` (SwiftUI `ScrollView` handles scrolling)
- `backgroundColor = .clear`
- Default typing font: `.systemFont(ofSize: 17)`
- `Coordinator: NSObject, UITextViewDelegate` syncs edits back via `Binding<NSAttributedString>`
- Exposes `selectedRange` and `textView` reference for toolbar actions

### Bottom Formatting Toolbar

Two panels toggled by a chevron (`›` / `‹`) button on the right end.

**Panel 1 (default):**
| Button | Action |
|--------|--------|
| `H` | Toggle heading: applies `.systemFont(ofSize: 22, weight: .bold)` to current line |
| `B` | Toggle bold on selection (`NSFontAttributeName` trait) |
| Highlight pen | Toggle yellow background color (`NSBackgroundColorAttributeName`) on selection |
| Checkbox | Insert `☐ ` at start of current line; tapping `☐` in editor toggles to `☑` |
| Bullet list | Insert `• ` at start of current line |
| Numbered list | Insert `N. ` at start of current line (N = count of preceding numbered lines + 1) |
| `›` | Switch to Panel 2 |

**Panel 2:**
| Button | Action |
|--------|--------|
| `‹` | Back to Panel 1 |
| Strikethrough | Toggle `NSStrikethroughStyleAttributeName` on selection |
| Divider | Insert a full-width `NSTextAttachment` horizontal rule at current line |
| Link | Show alert to enter URL, apply `NSLinkAttributeName` to selection |
| Code | Toggle monospace font (`.monospacedSystemFont(ofSize: 15)`) and light gray background on selection |
| Unlink | Remove `NSLinkAttributeName` (shown only when cursor is inside a link) |

### `NotebookManagerView` (sheet)
- List of notebooks with colored dot, name, note count
- Swipe to delete (moves notes to "no notebook")
- Tap to edit name/color inline (same `AddFolderView`-style sheet)
- "New Notebook" button at bottom with same color picker as AddListView/AddFolderView

---

## Feature Wiring

- `FeatureKey` — add `.notes = "notes"`
- `SidebarDestination` — add `case notes`
- `NotesFeature.swift` — `FeatureDefinition(key: .notes, displayName: "Notes", icon: "note.text")`
- Register in `LastAppApp.init()`: `FeatureRegistry.register(NotesFeature.definition)`
- Add `Note.self, NoteNotebook.self` to `ModelContainer` schema
- `ContentView.swift` — add `.notes: NoteListView()` case
- All exhaustive switches updated (`TaskListView.filteredTasks`, `TaskListView.navigationTitle`, etc.)

---

## File Layout

```
Features/Notes/
  NotesFeature.swift
  Models/
    Note.swift
    NoteNotebook.swift
  Views/
    NoteListView.swift
    NoteEditorView.swift
    RichTextEditor.swift
    NotebookManagerView.swift
```

---

## Out of Scope

- Reminders / due dates
- Attachments / images in notes
- Note sharing or export
- Onboarding flow
