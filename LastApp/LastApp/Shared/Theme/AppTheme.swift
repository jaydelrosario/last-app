// LastApp/Shared/Theme/AppTheme.swift
import SwiftUI
import UIKit

// MARK: - App Colors
extension Color {
    /// Teal accent: #14b8a6
    static let appAccent = Color(red: 0.082, green: 0.722, blue: 0.647)

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .p1: Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
        case .p2: Color(red: 0.976, green: 0.451, blue: 0.086) // #f97316
        case .p3: Color(red: 0.231, green: 0.510, blue: 0.965) // #3b82f6
        case .p4: Color(red: 0.420, green: 0.447, blue: 0.502) // #6b7280
        }
    }
}

// MARK: - Layout Constants
enum AppTheme {
    static let padding: CGFloat = 16
    static let rowSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 10
    static var sidebarWidth: CGFloat { UIScreen.main.bounds.width - 56 }
}
