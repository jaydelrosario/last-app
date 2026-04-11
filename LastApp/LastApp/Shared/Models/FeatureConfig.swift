// LastApp/Shared/Models/FeatureConfig.swift
import SwiftData
import Foundation

@Model
final class FeatureConfig {
    var id: UUID = UUID()
    var featureKeyRaw: String = ""
    var isEnabled: Bool = true
    var sortOrder: Int = 0

    var featureKey: FeatureKey {
        get { FeatureKey(rawValue: featureKeyRaw) ?? .tasks }
        set { featureKeyRaw = newValue.rawValue }
    }

    init(featureKey: FeatureKey, isEnabled: Bool = true, sortOrder: Int = 0) {
        self.featureKeyRaw = featureKey.rawValue
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
    }
}
