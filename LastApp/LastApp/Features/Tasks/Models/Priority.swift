// LastApp/Features/Tasks/Models/Priority.swift
import Foundation

enum Priority: Int, Codable, CaseIterable, Comparable {
    case p1 = 1, p2 = 2, p3 = 3, p4 = 4

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .p1: "High"
        case .p2: "Medium"
        case .p3: "Low"
        case .p4: "None"
        }
    }
}
