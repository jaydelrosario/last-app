// LastApp/Features/Weather/WeatherView.swift
import SwiftUI
import WeatherKit
import UIKit

struct WeatherView: View {
    @State private var viewModel = WeatherViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .denied:
                deniedView
            case .error(let message):
                errorView(message: message)
            case .loaded:
                loadedView
            }
        }
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.start() }
        .refreshable { viewModel.refresh() }
    }

    // MARK: - Loaded

    private var loadedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let current = viewModel.currentWeather,
                   let today = viewModel.forecast.first {
                    todayCard(current: current, today: today)
                }
                if !viewModel.forecast.isEmpty {
                    forecastList
                }
            }
            .padding(AppTheme.padding)
        }
    }

    private func todayCard(current: CurrentWeather, today: DayWeather) -> some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: current.symbolName)
                    .font(.system(size: 52))
                    .foregroundStyle(Color.appAccent)
                Text(conditionLabel(current.condition))
                    .font(.system(.title3, weight: .medium))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatTemp(current.temperature))
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                Text("H:\(formatTemp(today.highTemperature))  L:\(formatTemp(today.lowTemperature))")
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(Int(today.precipitationChance * 100))%")
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.padding)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var forecastList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.forecast.indices, id: \.self) { index in
                let day = viewModel.forecast[index]
                HStack(spacing: 12) {
                    Text(index == 0 ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated)))
                        .frame(width: 48, alignment: .leading)

                    Image(systemName: day.symbolName)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Spacer()

                    Text("\(Int(day.precipitationChance * 100))%")
                        .font(.system(.subheadline))
                        .foregroundStyle(day.precipitationChance > 0.1 ? .blue : Color.secondary.opacity(0.4))
                        .frame(width: 36, alignment: .trailing)

                    Text("\(formatTemp(day.highTemperature)) / \(formatTemp(day.lowTemperature))")
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, AppTheme.padding)

                if index < viewModel.forecast.count - 1 {
                    Divider().padding(.horizontal, AppTheme.padding)
                }
            }
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Error States

    private var deniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Location Access Required")
                .font(.system(.headline))
            Text("Enable location access in Settings to see your weather.")
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.appAccent)
        }
        .padding(AppTheme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Couldn't load weather")
                .font(.system(.headline))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") { viewModel.refresh() }
                .buttonStyle(.bordered)
                .tint(Color.appAccent)
        }
        .padding(AppTheme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatTemp(_ measurement: Measurement<UnitTemperature>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitOptions = .providedUnit
        let unit: UnitTemperature = Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
        return formatter.string(from: measurement.converted(to: unit))
    }

    private func conditionLabel(_ condition: WeatherCondition) -> String {
        let raw = String(describing: condition)
        var result = ""
        for (i, char) in raw.enumerated() {
            if char.isUppercase && i > 0 {
                result.append(" ")
            }
            result.append(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}
