// LastApp/Features/Tasks/Views/AddListView.swift
import SwiftUI
import SwiftData

struct AddListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskFolder.sortOrder) private var folders: [TaskFolder]

    var existingList: TaskList? = nil

    @State private var name = ""
    @State private var selectedColorHex = ""   // "" = no color, else 6-char hex or "custom"
    @State private var customColor: Color = Color(red: 0.4, green: 0.6, blue: 1.0)
    @State private var selectedViewType = "list"
    @State private var selectedFolder: TaskFolder? = nil

    private let presetColors: [(hex: String, color: Color)] = [
        ("ef4444", Color(red: 0.937, green: 0.267, blue: 0.267)),
        ("f97316", Color(red: 0.957, green: 0.451, blue: 0.086)),
        ("eab308", Color(red: 0.918, green: 0.702, blue: 0.031)),
        ("84cc16", Color(red: 0.518, green: 0.800, blue: 0.086)),
        ("22c55e", Color(red: 0.133, green: 0.773, blue: 0.369)),
        ("3b82f6", Color(red: 0.231, green: 0.510, blue: 0.965)),
    ]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameField
                    if !folders.isEmpty { folderSection }
                    colorSection
                    viewTypeSection
                }
                .padding(AppTheme.padding)
            }
            .navigationTitle(existingList == nil ? "Add List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { loadExisting() }
    }

    // MARK: - Name Field

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField("Name", text: $name)
        }
        .padding(AppTheme.padding)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Folder Section

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folder")
                .font(.system(.body, weight: .bold))

            VStack(spacing: 0) {
                // None option
                folderOption(label: "No Folder", icon: "xmark.circle", isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                }

                ForEach(folders) { folder in
                    Divider().padding(.leading, 44)
                    folderOption(
                        label: folder.name,
                        icon: "folder.fill",
                        iconColor: folder.colorHex.isEmpty ? nil : Color(hex: folder.colorHex),
                        isSelected: selectedFolder?.id == folder.id
                    ) {
                        selectedFolder = folder
                    }
                }
            }
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func folderOption(label: String, icon: String, iconColor: Color? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor ?? .secondary)
                    .frame(width: 20)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("List Color")
                .font(.system(.body, weight: .bold))

            HStack(spacing: 10) {
                // No color
                Button { selectedColorHex = "" } label: {
                    colorCircleLabel(color: Color.secondary.opacity(0.25), isSelected: selectedColorHex == "", isNone: true)
                }
                .buttonStyle(.plain)

                // Presets
                ForEach(presetColors, id: \.hex) { preset in
                    Button { selectedColorHex = preset.hex } label: {
                        colorCircleLabel(color: preset.color, isSelected: selectedColorHex == preset.hex)
                    }
                    .buttonStyle(.plain)
                }

                // Custom color picker
                ZStack {
                    ColorPicker(selection: $customColor, supportsOpacity: false) {
                        colorCircleLabel(
                            color: .clear,
                            isSelected: selectedColorHex == "custom",
                            isRainbow: true
                        )
                    }
                    .labelsHidden()
                    .frame(width: 42, height: 42)
                }
                .onChange(of: customColor) { _, _ in selectedColorHex = "custom" }
            }
        }
        .padding(AppTheme.padding)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func colorCircleLabel(color: Color, isSelected: Bool, isNone: Bool = false, isRainbow: Bool = false) -> some View {
        ZStack {
            if isRainbow {
                Circle()
                    .fill(
                        AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center)
                    )
                    .frame(width: 36, height: 36)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
            }
            if isNone {
                Image(systemName: "line.diagonal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .rotationEffect(.degrees(45))
            }
            if isSelected {
                Circle()
                    .strokeBorder(Color.appAccent, lineWidth: 2.5)
                    .frame(width: 43, height: 43)
            }
        }
        .frame(width: 43, height: 43)
    }

    // MARK: - View Type Section

    private var viewTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("View Type")
                .font(.system(.body, weight: .bold))

            HStack(spacing: 10) {
                viewTypeCard(type: "list", label: "List") { listThumbnail }
                viewTypeCard(type: "kanban", label: "Kanban") { kanbanThumbnail }
                disabledViewTypeCard(label: "Timeline") { timelineThumbnail }
            }
        }
        .padding(AppTheme.padding)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func viewTypeCard<Content: View>(type: String, label: String, @ViewBuilder thumbnail: () -> Content) -> some View {
        let isSelected = selectedViewType == type
        return Button { selectedViewType = type } label: {
            VStack(spacing: 8) {
                thumbnail()
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                    )
                Text(label)
                    .font(.system(.caption, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.appAccent : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func disabledViewTypeCard<Content: View>(label: String, @ViewBuilder thumbnail: () -> Content) -> some View {
        VStack(spacing: 8) {
            thumbnail()
                .frame(maxWidth: .infinity)
                .frame(height: 84)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)
                Text("👑")
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Thumbnails

    private var listThumbnail: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        .frame(width: 10, height: 10)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.25))
                        .frame(height: 6)
                    Spacer()
                }
            }
        }
        .padding(10)
    }

    private var kanbanThumbnail: some View {
        HStack(alignment: .top, spacing: 5) {
            ForEach(0..<3, id: \.self) { col in
                VStack(spacing: 4) {
                    ForEach(0..<(col == 1 ? 3 : 2), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 14)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
    }

    private var timelineThumbnail: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 0) {
                ForEach(["19","20","21","22","23"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 6))
                        .foregroundStyle(.quaternary)
                        .frame(maxWidth: .infinity)
                }
            }
            Divider().opacity(0.4)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red.opacity(0.3))
                .frame(height: 10)
                .padding(.leading, 8)
                .padding(.trailing, 24)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue.opacity(0.3))
                .frame(height: 10)
                .padding(.leading, 20)
                .padding(.trailing, 4)
        }
        .padding(8)
    }

    // MARK: - Helpers

    private func loadExisting() {
        guard let list = existingList else { return }
        name = list.name
        selectedViewType = list.viewType
        selectedFolder = list.folder
        let hex = list.colorHex
        let presetHexes = presetColors.map(\.hex)
        if hex.isEmpty {
            selectedColorHex = ""
        } else if presetHexes.contains(hex) {
            selectedColorHex = hex
        } else {
            selectedColorHex = "custom"
            customColor = Color(hex: hex)
        }
    }

    private func resolvedColorHex() -> String {
        if selectedColorHex == "custom" {
            let ui = UIColor(customColor)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: nil)
            return String(format: "%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
        }
        return selectedColorHex
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let hex = resolvedColorHex()
        if let list = existingList {
            list.name = trimmed
            list.colorHex = hex
            list.viewType = selectedViewType
            list.folder = selectedFolder
        } else {
            let list = TaskList(name: trimmed, colorHex: hex)
            list.viewType = selectedViewType
            list.folder = selectedFolder
            modelContext.insert(list)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddListView()
        .modelContainer(for: TaskList.self, inMemory: true)
}
