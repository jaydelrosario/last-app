// LastApp/Features/Notes/Views/NoteEditorView.swift
import SwiftUI
import SwiftData
import UIKit

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
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
                onTextChange: {},
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
            note.plainText = attributedText.string
            note.modifiedAt = Date()
            try? modelContext.save()
        }
    }
}
