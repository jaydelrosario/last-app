// LastApp/Core/Features/FeatureRegistry.swift
import Foundation

enum FeatureRegistry {
    private(set) static var all: [FeatureDefinition] = []

    static func register(_ definition: FeatureDefinition) {
        guard !all.contains(where: { $0.key == definition.key }) else { return }
        all.append(definition)
    }

    static func definition(for key: FeatureKey) -> FeatureDefinition? {
        all.first { $0.key == key }
    }
}
