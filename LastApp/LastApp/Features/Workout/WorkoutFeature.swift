// LastApp/LastApp/Features/Workout/WorkoutFeature.swift
import SwiftUI

enum WorkoutFeature {
    static let definition = FeatureDefinition(
        key: .workout,
        displayName: "Workout",
        icon: "dumbbell",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Workout", systemImage: "dumbbell")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(WorkoutListView())
        }
    )
}

// TEMPORARY — will be replaced in Task 6
struct WorkoutListView: View {
    var body: some View { Text("Workout Coming Soon") }
}
