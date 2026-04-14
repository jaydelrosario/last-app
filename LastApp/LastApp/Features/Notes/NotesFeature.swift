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
