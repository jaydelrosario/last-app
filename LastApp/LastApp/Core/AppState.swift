// LastApp/Core/AppState.swift
import SwiftUI

@Observable
final class AppState {
    var selectedDestination: SidebarDestination = .inbox
    var isSidebarOpen: Bool = false

    func navigate(to destination: SidebarDestination) {
        selectedDestination = destination
        isSidebarOpen = false
    }
}
