import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
    case workout = "workout"
    case cooking = "cooking"
    case notes = "notes"
    case weather = "weather"
}
