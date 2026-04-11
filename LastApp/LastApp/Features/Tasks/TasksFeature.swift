// LastApp/Features/Tasks/TasksFeature.swift
import SwiftUI

enum TasksFeature {
    static let definition = FeatureDefinition(
        key: .tasks,
        displayName: "Tasks",
        icon: "checkmark.circle",
        isAlwaysOn: true,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Tasks", systemImage: "checkmark.circle")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(TaskListView())
        }
    )
}
