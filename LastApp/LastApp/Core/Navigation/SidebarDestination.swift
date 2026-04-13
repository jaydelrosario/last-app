// LastApp/Core/Navigation/SidebarDestination.swift
import Foundation

enum SidebarDestination: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case list(UUID)
    case habits
    case workout
    case cooking
    case settings
}
