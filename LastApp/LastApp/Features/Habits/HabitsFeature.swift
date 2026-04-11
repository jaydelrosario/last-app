// LastApp/Features/Habits/HabitsFeature.swift
import SwiftUI

enum HabitsFeature {
    static let definition = FeatureDefinition(
        key: .habits,
        displayName: "Habits",
        icon: "flame",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Habits", systemImage: "flame")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(HabitListView())
        }
    )
}
