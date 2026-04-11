// LastApp/Shared/Models/FeatureLink.swift
import SwiftData
import Foundation

@Model
final class FeatureLink {
    var id: UUID = UUID()
    var sourceType: String = ""
    var sourceId: String = ""
    var targetType: String = ""
    var targetId: String = ""

    init(sourceType: String, sourceId: String, targetType: String, targetId: String) {
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.targetType = targetType
        self.targetId = targetId
    }
}
