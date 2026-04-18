// LastApp/Features/Weather/WeatherViewModel.swift
import Foundation
import WeatherKit
import CoreLocation

@Observable
@MainActor
final class WeatherViewModel: NSObject, CLLocationManagerDelegate {

    enum LoadingState {
        case loading
        case loaded
        case denied
        case error(String)
    }

    var currentWeather: CurrentWeather? = nil
    var forecast: [DayWeather] = []
    var state: LoadingState = .loading

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation? = nil

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            state = .denied
        @unknown default:
            state = .denied
        }
    }

    func refresh() {
        state = .loading
        if let location = lastLocation {
            fetchWeather(for: location)
        } else {
            start()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                state = .denied
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            lastLocation = location
            fetchWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - WeatherKit

    private func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                currentWeather = weather.currentWeather
                forecast = Array(weather.dailyForecast.prefix(10))
                state = .loaded
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
