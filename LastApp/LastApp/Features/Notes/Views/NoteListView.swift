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
                return note.plainText.lowercased().contains(q) ||
                       note.tags.contains(where: { $0.contains(q) })
            }()
            return matchesNotebook && matchesSearch
        }
    }

    private var pinnedNotes: [Note] { filteredNotes.filter { $0.isPinned } }
    private var unpinnedNotes: [Note] { filteredNotes.filter { !$0.isPinned } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()
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

                // Notes list or empty state
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
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                            if !pinnedNotes.isEmpty {
                                Section {
                                    ForEach(pinnedNotes) { note in
                                        SwipeNoteRow(note: note) {
                                            selectedNote = note
                                        } onDelete: {
                                            modelContext.delete(note)
                                            try? modelContext.save()
                                        } onPin: {
                                            note.isPinned.toggle()
                                            try? modelContext.save()
                                        }
                                    }
                                } header: {
                                    sectionHeader("PINNED")
                                }
                            }

                            if !unpinnedNotes.isEmpty {
                                Section {
                                    ForEach(unpinnedNotes) { note in
                                        SwipeNoteRow(note: note) {
                                            selectedNote = note
                                        } onDelete: {
                                            modelContext.delete(note)
                                            try? modelContext.save()
                                        } onPin: {
                                            note.isPinned.toggle()
                                            try? modelContext.save()
                                        }
                                    }
                                } header: {
                                    if !pinnedNotes.isEmpty {
                                        sectionHeader("NOTES")
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 90)
                    }
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
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

// MARK: - Custom swipe row

private struct SwipeNoteRow: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    @State private var offset: CGFloat = 0
    @State private var anchorOffset: CGFloat = 0
    private let actionWidth: CGFloat = 68

    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons revealed behind
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3)) { offset = 0 }
                    onPin()
                } label: {
                    Image(systemName: note.isPinned ? "pin.slash" : "pin")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color.appAccent)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.3)) { offset = 0 }
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.35))
                }
                .buttonStyle(.plain)
            }
            .frame(width: min(-offset, actionWidth * 2), alignment: .trailing)
            .clipped()

            // Note content (slides left up to max reveal)
            noteContent
                .offset(x: offset)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, 5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged { value in
                    // Only activate for primarily horizontal drags
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                    let maxReveal = actionWidth * 2
                    offset = min(0, max(-maxReveal, anchorOffset + value.translation.width))
                }
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if -offset > actionWidth {
                            offset = -actionWidth * 2
                            anchorOffset = -actionWidth * 2
                        } else {
                            offset = 0
                            anchorOffset = 0
                        }
                    }
                }
        )
    }

    private var noteContent: some View {
        Button(action: onTap) {
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
                            .foregroundStyle(nb.colorHex.isEmpty ? Color.secondary : Color(hex: nb.colorHex))
                    }
                    ForEach(note.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(.caption2))
                            .foregroundStyle(Color.appAccent.opacity(0.8))
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, AppTheme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
