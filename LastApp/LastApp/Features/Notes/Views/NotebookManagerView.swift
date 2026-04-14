// LastApp/Features/Notes/Views/NotebookManagerView.swift
import SwiftUI
import SwiftData

struct NotebookManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteNotebook.sortOrder) private var notebooks: [NoteNotebook]

    @State private var showingAdd = false
    @State private var editingNotebook: NoteNotebook? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(notebooks) { nb in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(nb.colorHex.isEmpty ? Color.secondary.opacity(0.4) : Color(hex: nb.colorHex))
                            .frame(width: 12, height: 12)
                        Text(nb.name)
                        Spacer()
                        Text("\(nb.notes.count)")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                        Button { editingNotebook = nb } label: {
                            Image(systemName: "pencil")
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    offsets.map { notebooks[$0] }.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                }
            }
            .navigationTitle("Notebooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { NotebookFormView() }
            .sheet(item: $editingNotebook) { NotebookFormView(existing: $0) }
        }
    }
}

struct NotebookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteNotebook.sortOrder) private var notebooks: [NoteNotebook]

    var existing: NoteNotebook? = nil

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
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    TextField("Notebook name", text: $name)
                }
                .padding(AppTheme.padding)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    Button { selectedColorHex = "" } label: {
                        colorCircle(color: Color.secondary.opacity(0.25), isSelected: selectedColorHex == "", isNone: true)
                    }.buttonStyle(.plain)

                    ForEach(presetColors, id: \.hex) { preset in
                        Button { selectedColorHex = preset.hex } label: {
                            colorCircle(color: preset.color, isSelected: selectedColorHex == preset.hex)
                        }.buttonStyle(.plain)
                    }

                    ZStack {
                        ColorPicker(selection: $customColor, supportsOpacity: false) {
                            colorCircle(color: .clear, isSelected: selectedColorHex == "custom", isRainbow: true)
                        }
                        .labelsHidden()
                        .frame(width: 42, height: 42)
                    }
                    .onChange(of: customColor) { _, _ in selectedColorHex = "custom" }
                }

                Spacer()
            }
            .padding(AppTheme.padding)
            .navigationTitle(existing == nil ? "New Notebook" : "Edit Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let nb = existing {
                name = nb.name
                selectedColorHex = nb.colorHex
            }
        }
    }

    private func colorCircle(color: Color, isSelected: Bool, isNone: Bool = false, isRainbow: Bool = false) -> some View {
        ZStack {
            if isRainbow {
                Circle().fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center)).frame(width: 36, height: 36)
            } else {
                Circle().fill(color).frame(width: 36, height: 36)
            }
            if isNone { Image(systemName: "line.diagonal").font(.system(size: 18, weight: .medium)).foregroundStyle(.secondary).rotationEffect(.degrees(45)) }
            if isSelected { Circle().strokeBorder(Color.appAccent, lineWidth: 2.5).frame(width: 43, height: 43) }
        }
        .frame(width: 43, height: 43)
    }

    private func resolvedHex() -> String {
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
        let hex = resolvedHex()
        if let nb = existing {
            nb.name = trimmed
            nb.colorHex = hex
        } else {
            let maxOrder = notebooks.map(\.sortOrder).max() ?? -1
            let nb = NoteNotebook(name: trimmed, colorHex: hex, sortOrder: maxOrder + 1)
            modelContext.insert(nb)
        }
        try? modelContext.save()
        dismiss()
    }
}
