// LastApp/LastApp/Features/Cooking/CookingFeature.swift
import SwiftUI

enum CookingFeature {
    static let definition = FeatureDefinition(
        key: .cooking,
        displayName: "Cooking",
        icon: "fork.knife",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Cooking", systemImage: "fork.knife")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(RecipeListView())
        }
    )
}
