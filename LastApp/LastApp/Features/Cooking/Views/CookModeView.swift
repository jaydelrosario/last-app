// LastApp/LastApp/Features/Cooking/Views/CookModeView.swift
import SwiftUI

struct CookModeView: View {
    var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Text("Cook mode coming soon")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }
}
