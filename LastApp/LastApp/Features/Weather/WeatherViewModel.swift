// LastApp/Features/Weather/WeatherViewModel.swift
import Foundation
import WeatherKit
import CoreLocation

@Observable
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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            state = .denied
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        lastLocation = location
        fetchWeather(for: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .error(error.localizedDescription)
    }

    // MARK: - WeatherKit

    private func fetchWeather(for location: CLLocation) {
        Task { @MainActor in
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                self.currentWeather = weather.currentWeather
                self.forecast = Array(weather.dailyForecast.prefix(10))
                self.state = .loaded
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
