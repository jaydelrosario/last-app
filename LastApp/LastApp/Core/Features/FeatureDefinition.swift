// LastApp/Core/Features/FeatureDefinition.swift
import SwiftUI

struct FeatureDefinition {
    let key: FeatureKey
    let displayName: String
    let icon: String
    let isAlwaysOn: Bool
    let makeSidebarRow: (_ isSelected: Bool, _ onSelect: @escaping () -> Void) -> AnyView
    let makeRootView: (_ appState: AppState) -> AnyView
}
