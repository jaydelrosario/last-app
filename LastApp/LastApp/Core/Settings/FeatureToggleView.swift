// LastApp/Core/Settings/FeatureToggleView.swift
import SwiftUI

struct FeatureToggleView: View {
    let definition: FeatureDefinition
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: definition.icon)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(width: 28, alignment: .center)

            Text(definition.displayName)
                .font(.system(.body))

            Spacer()

            if definition.isAlwaysOn {
                Text("Always on")
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)
            } else {
                Toggle("", isOn: $isEnabled)
                    .tint(Color.appAccent)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 2)
    }
}
