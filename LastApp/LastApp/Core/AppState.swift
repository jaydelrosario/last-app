// LastApp/Core/AppState.swift
import SwiftUI

@Observable
final class AppState {
    var selectedDestination: SidebarDestination = .inbox
    var isSidebarOpen: Bool = false
    var navigationPath = NavigationPath()

    func navigate(to destination: SidebarDestination) {
        selectedDestination = destination
        navigationPath = NavigationPath()
        isSidebarOpen = false
    }
}
