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
