// LastApp/Core/Navigation/SidebarView.swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]
    @Query(filter: #Predicate<FeatureConfig> { $0.isEnabled }, sort: \FeatureConfig.sortOrder)
    private var enabledFeatures: [FeatureConfig]

    @State private var showingAddList = false
    @State private var editingList: TaskList?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    smartListsSection
                    listsSection
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
        .sheet(isPresented: $showingAddList) { AddListView() }
        .sheet(item: $editingList) { AddListView(existingList: $0) }
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

    private var listsSection: some View {
        Group {
            HStack {
                Text("LISTS")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button { showingAddList = true } label: {
                    Image(systemName: "plus")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(customLists) { list in
                sidebarRow(
                    icon: list.icon,
                    label: list.name,
                    destination: .list(list.id),
                    tintColor: list.colorHex.isEmpty ? nil : Color(hex: list.colorHex)
                )
                .contextMenu {
                    Button { editingList = list } label: {
                        Label("Edit List", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(list)
                        try? modelContext.save()
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                }
            }
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

    private func sidebarRow(icon: String, label: String, destination: SidebarDestination, tintColor: Color? = nil) -> some View {
        let isSelected = appState.selectedDestination == destination
        let iconColor: Color = tintColor ?? (isSelected ? Color.appAccent : .primary)
        return Button {
            appState.navigate(to: destination)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(iconColor)
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
