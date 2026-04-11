// LastApp/Features/Habits/HabitsFeature.swift
import SwiftUI

enum HabitsFeature {
    static let definition = FeatureDefinition(
        key: .habits,
        displayName: "Habits",
        icon: "flame",
        isAlwaysOn: false,
        makeSidebarRow: { _, _ in AnyView(EmptyView()) },
        makeRootView: { _ in AnyView(EmptyView()) }
    )
}
