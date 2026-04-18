// LastApp/Features/Weather/WeatherFeature.swift
import SwiftUI

enum WeatherFeature {
    static let definition = FeatureDefinition(
        key: .weather,
        displayName: "Weather",
        icon: "cloud.sun",
        isAlwaysOn: false,
        makeSidebarRow: { isSelected, onSelect in
            AnyView(
                Button(action: onSelect) {
                    Label("Weather", systemImage: "cloud.sun")
                        .foregroundStyle(isSelected ? Color.appAccent : .primary)
                }
                .buttonStyle(.plain)
            )
        },
        makeRootView: { _ in
            AnyView(WeatherView())
        }
    )
}
