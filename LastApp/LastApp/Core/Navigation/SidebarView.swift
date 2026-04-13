// LastApp/Core/Navigation/SidebarView.swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]
    @Query(filter: #Predicate<FeatureConfig> { $0.isEnabled }, sort: \FeatureConfig.sortOrder)
    private var enabledFeatures: [FeatureConfig]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    smartListsSection
                    if !customLists.isEmpty {
                        sectionLabel("LISTS")
                        customListsSection
                    }
                    enabledFeaturesSection
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            Spacer()
            settingsRow
        }
        .frame(width: AppTheme.sidebarWidth)
        .background(.regularMaterial)
    }

    // MARK: - Sections

    private var sidebarHeader: some View {
        Text("LastApp")
            .font(.system(.title2, design: .rounded, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
    }

    private var smartListsSection: some View {
        Group {
            sidebarRow(icon: "tray", label: "Inbox", destination: .inbox)
            sidebarRow(icon: "sun.max", label: "Today", destination: .today)
            sidebarRow(icon: "calendar", label: "Upcoming", destination: .upcoming)
            sidebarRow(icon: "checkmark.circle", label: "Completed", destination: .completed)
        }
    }

    private var customListsSection: some View {
        ForEach(customLists) { list in
            sidebarRow(icon: list.icon, label: list.name, destination: .list(list.id))
        }
    }

    private var enabledFeaturesSection: some View {
        ForEach(enabledFeatures, id: \.id) { config in
            if let feature = FeatureRegistry.definition(for: config.featureKey),
               !feature.isAlwaysOn {
                sectionLabel(feature.displayName.uppercased())
                sidebarRow(
                    icon: feature.icon,
                    label: feature.displayName,
                    destination: destinationFor(config.featureKey)
                )
            }
        }
    }

    private var settingsRow: some View {
        Button {
            appState.navigate(to: .settings)
        } label: {
            Label("Settings", systemImage: "gearshape")
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sidebarRow(icon: String, label: String, destination: SidebarDestination) -> some View {
        let isSelected = appState.selectedDestination == destination
        return Button {
            appState.navigate(to: destination)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(isSelected ? Color.appAccent : .primary)
                Text(label)
                    .font(.system(.body))
                    .foregroundStyle(isSelected ? Color.appAccent : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.appAccent.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func destinationFor(_ key: FeatureKey) -> SidebarDestination {
        switch key {
        case .tasks: .inbox
        case .habits: .habits
        case .workout: .workout
        case .cooking: .cooking
        }
    }
}
