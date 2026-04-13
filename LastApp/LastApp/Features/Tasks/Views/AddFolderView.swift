// LastApp/Features/Tasks/Views/AddFolderView.swift
import SwiftUI
import SwiftData

struct AddFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingFolder: TaskFolder? = nil

    @State private var name = ""
    @State private var selectedColorHex = ""
    @State private var customColor: Color = Color(red: 0.4, green: 0.6, blue: 1.0)

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
                    colorSection
                }
                .padding(AppTheme.padding)
            }
            .navigationTitle(existingFolder == nil ? "New Folder" : "Edit Folder")
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

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField("Folder name", text: $name)
        }
        .padding(AppTheme.padding)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Folder Color")
                .font(.system(.body, weight: .bold))

            HStack(spacing: 10) {
                Button { selectedColorHex = "" } label: {
                    colorCircleLabel(color: Color.secondary.opacity(0.25), isSelected: selectedColorHex == "", isNone: true)
                }
                .buttonStyle(.plain)

                ForEach(presetColors, id: \.hex) { preset in
                    Button { selectedColorHex = preset.hex } label: {
                        colorCircleLabel(color: preset.color, isSelected: selectedColorHex == preset.hex)
                    }
                    .buttonStyle(.plain)
                }

                ZStack {
                    ColorPicker(selection: $customColor, supportsOpacity: false) {
                        colorCircleLabel(color: .clear, isSelected: selectedColorHex == "custom", isRainbow: true)
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
                    .fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center))
                    .frame(width: 36, height: 36)
            } else {
                Circle().fill(color).frame(width: 36, height: 36)
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

    private func loadExisting() {
        guard let folder = existingFolder else { return }
        name = folder.name
        let hex = folder.colorHex
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
        if let folder = existingFolder {
            folder.name = trimmed
            folder.colorHex = hex
        } else {
            let folder = TaskFolder(name: trimmed, colorHex: hex)
            modelContext.insert(folder)
        }
        try? modelContext.save()
        dismiss()
    }
}
