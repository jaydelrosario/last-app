// LastApp/Core/Navigation/SidebarView.swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskFolder.sortOrder) private var folders: [TaskFolder]
    @Query(sort: \TaskList.sortOrder) private var allLists: [TaskList]
    @Query(filter: #Predicate<FeatureConfig> { $0.isEnabled }, sort: \FeatureConfig.sortOrder)
    private var enabledFeatures: [FeatureConfig]

    @State private var showingAddList = false
    @State private var editingList: TaskList?
    @State private var showingAddFolder = false
    @State private var editingFolder: TaskFolder?

    // Top-level lists (no folder)
    private var rootLists: [TaskList] {
        allLists.filter { $0.folder == nil }
    }

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
        .sheet(isPresented: $showingAddFolder) { AddFolderView() }
        .sheet(item: $editingFolder) { AddFolderView(existingFolder: $0) }
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        Text("LastApp")
            .font(.system(.title2, design: .rounded, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
    }

    // MARK: - Smart lists

    private var smartListsSection: some View {
        Group {
            sidebarRow(icon: "tray", label: "Inbox", destination: .inbox)
            sidebarRow(icon: "sun.max", label: "Today", destination: .today)
            sidebarRow(icon: "calendar", label: "Upcoming", destination: .upcoming)
            sidebarRow(icon: "checkmark.circle", label: "Completed", destination: .completed)
        }
    }

    // MARK: - Lists + Folders

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("LISTS")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button { showingAddList = true } label: {
                        Label("New List", systemImage: "list.bullet")
                    }
                    Button { showingAddFolder = true } label: {
                        Label("New Folder", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.body))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 4)

            // Folders (with their lists nested inside)
            ForEach(folders) { folder in
                folderRow(folder)
            }

            // Top-level lists (no folder)
            ForEach(rootLists) { list in
                listRow(list, indented: false)
            }

            // Empty state hint
            if folders.isEmpty && rootLists.isEmpty {
                Button { showingAddList = true } label: {
                    Label("Add a list", systemImage: "plus")
                        .font(.system(.subheadline))
                        .foregroundStyle(Color.appAccent.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Folder row

    private func folderRow(_ folder: TaskFolder) -> some View {
        @Bindable var folder = folder
        return VStack(alignment: .leading, spacing: 0) {
            // Folder header
            Button {
                withAnimation(.spring(response: 0.25)) { folder.isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: folder.isExpanded ? "folder.fill" : "folder")
                        .font(.system(.body, weight: .medium))
                        .frame(width: 22, alignment: .center)
                        .foregroundStyle(folder.colorHex.isEmpty ? .secondary : Color(hex: folder.colorHex))
                    Text(folder.name)
                        .font(.system(.body))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(folder.isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button { editingFolder = folder } label: {
                    Label("Edit Folder", systemImage: "pencil")
                }
                Button { showingAddList = true } label: {
                    Label("Add List to Folder", systemImage: "plus")
                }
                Divider()
                Button(role: .destructive) {
                    modelContext.delete(folder)
                    try? modelContext.save()
                } label: {
                    Label("Delete Folder", systemImage: "trash")
                }
            }

            // Nested lists
            if folder.isExpanded {
                let sorted = folder.lists.sorted { $0.sortOrder < $1.sortOrder }
                ForEach(sorted) { list in
                    listRow(list, indented: true)
                }
            }
        }
    }

    // MARK: - List row

    private func listRow(_ list: TaskList, indented: Bool) -> some View {
        let isSelected = appState.selectedDestination == .list(list.id)
        let tint: Color = list.colorHex.isEmpty ? (isSelected ? Color.appAccent : .primary) : Color(hex: list.colorHex)
        return Button {
            appState.navigate(to: .list(list.id))
        } label: {
            HStack(spacing: 12) {
                if indented {
                    Spacer().frame(width: 22)
                }
                Image(systemName: list.icon)
                    .font(.system(.body, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(tint)
                Text(list.name)
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

    // MARK: - Features

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

    // MARK: - Settings

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
