# Weather Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal Weather feature showing today's conditions and a 10-day forecast using the device's GPS location via Apple WeatherKit.

**Architecture:** `WeatherViewModel` (`@Observable`) owns `CLLocationManager` and `WeatherService` calls, exposing `currentWeather`, `forecast`, and a `LoadingState`. `WeatherView` renders a today card and 10-day list. Registered as a standard LastApp plugin via `FeatureKey` / `FeatureRegistry`.

**Tech Stack:** SwiftUI, WeatherKit, CoreLocation, iOS 17+

---

## File Map

**Create:**
- `LastApp/LastApp/Features/Weather/WeatherFeature.swift` — feature registration constant
- `LastApp/LastApp/Features/Weather/WeatherViewModel.swift` — location + WeatherKit fetching, state management
- `LastApp/LastApp/Features/Weather/WeatherView.swift` — full UI (today card + 10-day list + states)

**Modify:**
- `LastApp/LastApp/Core/Features/FeatureKey.swift` — add `.weather`
- `LastApp/LastApp/Core/Navigation/SidebarDestination.swift` — add `case weather`
- `LastApp/LastApp/LastAppApp.swift` — register `WeatherFeature.definition`
- `LastApp/LastApp/ContentView.swift` — add `.weather` case → `WeatherView()`
- `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift` — add `.weather` to both exhaustive switches

---

## Task 1: Manual Xcode Prerequisites

> **This task cannot be automated — it requires Xcode UI interactions and an Apple Developer Portal step.**

**Files:** Xcode project settings (via UI), Apple Developer Portal

- [ ] **Step 1: Accept WeatherKit terms on Apple Developer Portal**

Go to [developer.apple.com/account](https://developer.apple.com/account) → Certificates, Identifiers & Profiles → Identifiers → select your LastApp app ID → enable WeatherKit and accept terms. Without this, WeatherKit calls will return a `401` error even if the code is correct.

- [ ] **Step 2: Enable WeatherKit capability in Xcode**

Open `LastApp/LastApp.xcodeproj` in Xcode. Select the **LastApp** target → **Signing & Capabilities** tab → click **+ Capability** → search **WeatherKit** → double-click to add it. This auto-creates `LastApp/LastApp/LastApp.entitlements` with the WeatherKit entitlement.

- [ ] **Step 3: Add location permission description**

With the project open in Xcode, select the **LastApp** target → **Info** tab → under **Custom iOS Target Properties**, click **+** → add key `NSLocationWhenInUseUsageDescription` with value:
```
LastApp uses your location to show local weather.
```

- [ ] **Step 4: Build and verify**

Press Cmd+B. Expected: Build Succeeded. If WeatherKit is not yet active on the portal (can take a few minutes after accepting terms), the build will succeed but WeatherKit calls will fail at runtime with `401` — that's acceptable for now.

- [ ] **Step 5: Commit**

```bash
git add LastApp/LastApp/LastApp.entitlements LastApp/LastApp.xcodeproj/project.pbxproj
git commit -m "feat(weather): add WeatherKit capability and location permission"
```

---

## Task 2: Navigation Wiring

**Files:**
- Modify: `LastApp/LastApp/Core/Features/FeatureKey.swift`
- Modify: `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`
- Modify: `LastApp/LastApp/LastAppApp.swift`
- Modify: `LastApp/LastApp/ContentView.swift`
- Modify: `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift`

- [ ] **Step 1: Add `.weather` to FeatureKey**

Replace the entire file `LastApp/LastApp/Core/Features/FeatureKey.swift`:

```swift
import Foundation

enum FeatureKey: String, Codable, CaseIterable {
    case tasks = "tasks"
    case habits = "habits"
    case workout = "workout"
    case cooking = "cooking"
    case notes = "notes"
    case weather = "weather"
}
```

- [ ] **Step 2: Add `case weather` to SidebarDestination**

Replace the entire file `LastApp/LastApp/Core/Navigation/SidebarDestination.swift`:

```swift
// LastApp/Core/Navigation/SidebarDestination.swift
import Foundation

enum SidebarDestination: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case list(UUID)
    case habits
    case workout
    case cooking
    case notes
    case weather
    case settings
}
```

- [ ] **Step 3: Wire `.weather` in ContentView**

In `LastApp/LastApp/ContentView.swift`, update the `destinationView` computed property to add the `.weather` case. Replace the `destinationView` body:

```swift
@ViewBuilder
private var destinationView: some View {
    switch appState.selectedDestination {
    case .inbox, .upcoming, .completed, .list:
        TaskListView()
    case .today:
        TodayView()
    case .habits:
        HabitListView()
    case .workout:
        WorkoutListView()
    case .cooking:
        RecipeListView()
    case .notes:
        NoteListView()
    case .weather:
        WeatherView()
    case .settings:
        SettingsView()
    }
}
```

- [ ] **Step 4: Add `.weather` to TaskListView exhaustive switches**

In `LastApp/LastApp/Features/Tasks/Views/TaskListView.swift`, find the two switch cases that list `.habits, .workout, .cooking, .notes, .settings` and add `.weather` to both:

```swift
// In filteredTasks:
case .habits, .workout, .cooking, .notes, .weather, .settings:
    return []

// In navigationTitle:
case .habits, .workout, .cooking, .notes, .weather, .settings: ""
```

- [ ] **Step 5: Register WeatherFeature in LastAppApp**

In `LastApp/LastApp/LastAppApp.swift`, add `FeatureRegistry.register(WeatherFeature.definition)` to the `init()` body:

```swift
init() {
    FeatureRegistry.register(TasksFeature.definition)
    FeatureRegistry.register(HabitsFeature.definition)
    FeatureRegistry.register(WorkoutFeature.definition)
    FeatureRegistry.register(CookingFeature.definition)
    FeatureRegistry.register(NotesFeature.definition)
    FeatureRegistry.register(WeatherFeature.definition)
}
```

- [ ] **Step 6: Build and verify**

Press Cmd+B. Expected: Build fails with "Cannot find type 'WeatherView' in scope" and "Cannot find 'WeatherFeature' in scope" — that's expected since those files don't exist yet. No other errors.

- [ ] **Step 7: Commit**

```bash
git add LastApp/LastApp/Core/Features/FeatureKey.swift \
        LastApp/LastApp/Core/Navigation/SidebarDestination.swift \
        LastApp/LastApp/ContentView.swift \
        LastApp/LastApp/Features/Tasks/Views/TaskListView.swift \
        LastApp/LastApp/LastAppApp.swift
git commit -m "feat(weather): add navigation wiring for Weather feature"
```

---

## Task 3: WeatherViewModel

**Files:**
- Create: `LastApp/LastApp/Features/Weather/WeatherViewModel.swift`

- [ ] **Step 1: Create WeatherViewModel.swift**

Create `LastApp/LastApp/Features/Weather/WeatherViewModel.swift`:

```swift
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
```

- [ ] **Step 2: Build and verify**

Press Cmd+B. Expected: Build fails only on missing `WeatherView` and `WeatherFeature` — not on `WeatherViewModel` itself.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp/Features/Weather/WeatherViewModel.swift
git commit -m "feat(weather): add WeatherViewModel with CLLocationManager and WeatherKit fetching"
```

---

## Task 4: WeatherView + WeatherFeature

**Files:**
- Create: `LastApp/LastApp/Features/Weather/WeatherView.swift`
- Create: `LastApp/LastApp/Features/Weather/WeatherFeature.swift`

- [ ] **Step 1: Create WeatherView.swift**

Create `LastApp/LastApp/Features/Weather/WeatherView.swift`:

```swift
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

    /// Format a temperature Measurement respecting device locale (°F or °C).
    private func formatTemp(_ measurement: Measurement<UnitTemperature>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitOptions = .providedUnit
        // Convert to locale-preferred unit
        let locale = Locale.current
        let unit: UnitTemperature = locale.measurementSystem == .us ? .fahrenheit : .celsius
        return formatter.string(from: measurement.converted(to: unit))
    }

    /// Convert WeatherCondition enum to a display-friendly string.
    /// e.g. .mostlyCloudy → "Mostly Cloudy"
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
```

- [ ] **Step 2: Create WeatherFeature.swift**

Create `LastApp/LastApp/Features/Weather/WeatherFeature.swift`:

```swift
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
```

- [ ] **Step 3: Build and verify — full build should succeed**

Press Cmd+B. Expected: **Build Succeeded** with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add LastApp/LastApp/Features/Weather/WeatherView.swift \
        LastApp/LastApp/Features/Weather/WeatherFeature.swift
git commit -m "feat(weather): add WeatherView and WeatherFeature registration"
```

---

## Task 5: Manual Verification

- [ ] **Step 1: Run on simulator**

Press Cmd+R. Select an iPhone simulator.

> **Note:** WeatherKit does NOT work on the simulator — it requires a real device with an active Apple ID signed in. For simulator testing, the app will show the error state ("Couldn't load weather") which is expected. All other states (loading spinner, denied UI, pull-to-refresh) can be tested on simulator.

- [ ] **Step 2: Verify sidebar**

Open the sidebar. Confirm "Weather" appears in the features list with the `cloud.sun` icon. Tap it to navigate to WeatherView.

- [ ] **Step 3: Verify on a real device (required for WeatherKit)**

Build and run on a physical iPhone. Ensure you are signed into an Apple ID on the device (Settings → Apple ID). On first open of the Weather tab:
- Location permission prompt appears
- Grant permission
- Loading spinner shows briefly
- Today card appears: large icon, current temp, H/L, precip %
- 10-day forecast list shows below

- [ ] **Step 4: Test pull-to-refresh**

Pull down on the weather screen. Confirm the list refreshes and the data updates.

- [ ] **Step 5: Test location denied**

On simulator or device, go to Settings → Privacy → Location Services → LastApp → set to Never. Return to app, open Weather tab. Confirm the "Location Access Required" message with "Open Settings" button appears. Tap "Open Settings" — confirm it deep-links to the app's location settings.

- [ ] **Step 6: Final commit**

```bash
git commit --allow-empty -m "feat(weather): Weather feature complete and manually verified"
```
