// LastApp/Features/Tasks/TasksFeature.swift
import SwiftUI

enum TasksFeature {
    static let definition = FeatureDefinition(
        key: .tasks,
        displayName: "Tasks",
        icon: "checkmark.circle",
        isAlwaysOn: true,
        makeSidebarRow: { _, _ in AnyView(EmptyView()) },
        makeRootView: { _ in AnyView(EmptyView()) }
    )
}
