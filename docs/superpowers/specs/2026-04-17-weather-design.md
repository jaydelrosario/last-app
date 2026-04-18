# Weather Feature — Design Spec
_Date: 2026-04-17_

## Overview

A minimal Weather feature that shows today's conditions and a 10-day forecast using the device's current GPS location. Built as a standard LastApp plugin (FeatureKey → FeatureDefinition → FeatureRegistry).

---

## Decisions

| Decision | Choice |
|---|---|
| API | Apple WeatherKit (free ≤500K calls/month, no API key) |
| Location | Auto — current GPS location via CLLocationManager |
| Architecture | ViewModel pattern (`@Observable` WeatherViewModel) |
| Units | Device locale (°F in US, °C elsewhere — automatic via Measurement formatting) |
| Refresh | On view appear + pull-to-refresh; no background refresh |

---

## Architecture

### Files to Create

- `LastApp/LastApp/Features/Weather/WeatherFeature.swift` — feature registration
- `LastApp/LastApp/Features/Weather/WeatherViewModel.swift` — location + WeatherKit data fetching, loading state
- `LastApp/LastApp/Features/Weather/WeatherView.swift` — full UI: today card + 10-day list

### Files to Modify

- `LastApp/LastApp/Core/Features/FeatureKey.swift` — add `.weather`
- `LastApp/LastApp/Core/Navigation/SidebarDestination.swift` — add `case weather`
- `LastApp/LastApp/LastAppApp.swift` — register `WeatherFeature.definition`
- `LastApp/LastApp/ContentView.swift` — add `.weather` case → `WeatherView()`
- `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` — add `.weather` to exhaustive switches

### Xcode Project Setup (manual, one-time)

1. Enable the **WeatherKit** capability on the LastApp target (Xcode → Signing & Capabilities → + WeatherKit)
2. Accept WeatherKit terms on the Apple Developer portal
3. Add `NSLocationWhenInUseUsageDescription` to Info.plist

---

## WeatherViewModel

```swift
@Observable
final class WeatherViewModel: NSObject, CLLocationManagerDelegate {
    enum State { case loading, loaded, denied, error(String) }

    var currentWeather: CurrentWeather? = nil
    var forecast: [DayWeather] = []
    var state: State = .loading

    private let locationManager = CLLocationManager()

    func start() { /* request location, kick off fetch */ }
    func refresh() { /* re-fetch with last known location */ }
}
```

- On `start()`: requests "when in use" authorization, then calls `locationManager.requestLocation()`
- On `locationManager(_:didUpdateLocations:)`: calls `WeatherService.shared.weather(for:)` 
- Stores `currentWeather` and `forecast` (first 10 entries of `dailyForecast`)
- Sets `state` to `.loaded`, `.denied`, or `.error`

---

## Data Mapping

### Today card (from `CurrentWeather`)

| Display | WeatherKit property |
|---|---|
| Condition icon | `condition.symbolName` (SF Symbol) |
| Current temp | `temperature` |
| High / Low | `dailyForecast[0].highTemperature` / `lowTemperature` |
| Precip chance | `dailyForecast[0].precipitationChance` (formatted as %) |

### 10-day forecast (from `DayWeather` array, indices 0–9)

| Display | WeatherKit property |
|---|---|
| Day name | `date` formatted as "EEE" (Mon, Tue…), first entry = "Today" |
| Condition icon | `condition.symbolName` |
| High / Low | `highTemperature` / `lowTemperature` |
| Precip chance | `precipitationChance` (formatted as %) |

---

## UI Layout

### Today Card

```
┌─────────────────────────────┐
│  ☁️  Cloudy                  │
│  68°          H:74° L:58°   │
│               💧 30%         │
└─────────────────────────────┘
```

- Rounded card with background fill
- Large SF Symbol (font size ~52)
- Current temp in large bold text (~52pt)
- High/low and precip grouped to the right

### 10-Day Forecast List

```
Today    🌤   74° / 58°   💧 10%
Sat      🌧   65° / 52°   💧 80%
Sun      ☀️   72° / 55°   💧  0%
```

- Plain list rows, no separators
- Day name left-aligned, icon center, temps and precip right-aligned

### Loading / Error States

| State | UI |
|---|---|
| Loading | Centered `ProgressView` |
| Location denied | Centered message + "Open Settings" button (deep-links to `UIApplication.openSettingsURLString`) |
| Error | Centered error message + "Retry" button |

---

## Permissions

- `NSLocationWhenInUseUsageDescription` in Info.plist: `"LastApp uses your location to show local weather."`
- Permission prompt triggered on first view appear
- No location stored — used only for the WeatherKit call
