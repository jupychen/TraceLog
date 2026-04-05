import Foundation
import CoreLocation

@MainActor
class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var currentLocation: CLLocation?
    @Published var todaysLogs: [LocationLog] = []

    private let manager = CLLocationManager()
    private var storageService: StorageService?
    private var settingsService: SettingsService?
    private var timer: Timer?

    // Inject services after init (to avoid retain cycles)
    func inject(storage: StorageService, settings: SettingsService) {
        self.storageService = storage
        self.settingsService = settings
    }

    // MARK: - Lifecycle

    func start() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // Energy efficient
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        manager.distanceFilter = kCLDistanceFilterNone // We handle distance filtering ourselves

        requestPermission()
    }

    func enableTracking() {
        isTracking = true
        requestPermission()
    }

    func disableTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        storageService?.closeActiveLog()
    }

    private func requestPermission() {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization() // Background tracking
        case .authorizedAlways, .authorizedWhenInUse:
            startTrackingTimer()
        case .denied, .restricted:
            isTracking = false
        @unknown default:
            break
        }
    }

    // MARK: - Tracking Timer

    private func startTrackingTimer() {
        timer?.invalidate()
        let interval = settingsService?.timeInterval ?? 60.0

        // Get initial location immediately
        manager.startUpdatingLocation()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLocation()
            }
        }
    }

    private func checkLocation() {
        guard isTracking, let location = currentLocation else { return }
        processLocation(location)
    }

    // MARK: - Core Tracking Logic

    private func processLocation(_ location: CLLocation) {
        guard let storage = storageService else { return }

        let distanceThreshold = settingsService?.distanceInterval ?? 100.0

        if let activeLog = storage.getActiveLog() {
            // Calculate distance from the active log's position
            let logLocation = CLLocation(latitude: activeLog.latitude, longitude: activeLog.longitude)
            let distance = location.distance(from: logLocation)

            if distance > distanceThreshold {
                // Moved beyond threshold — close current log, create new one
                storage.closeActiveLog()

                let newLog = LocationLog(
                    startTime: Date(),
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                storage.insert(newLog)
            } else {
                // Still within threshold — just extend endTime
                var updatedLog = activeLog
                updatedLog = LocationLog(
                    id: activeLog.id,
                    startTime: activeLog.startTime,
                    endTime: Date(),
                    latitude: activeLog.latitude,
                    longitude: activeLog.longitude
                )
                storage.update(updatedLog)
            }
        } else {
            // No active log — create first one
            let newLog = LocationLog(
                startTime: Date(),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            storage.insert(newLog)
        }

        // Refresh today's logs for UI
        loadTodaysLogs()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            if self.isTracking {
                self.processLocation(location)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                if self.isTracking {
                    self.startTrackingTimer()
                }
            case .denied, .restricted:
                self.isTracking = false
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    // MARK: - Helper

    private func loadTodaysLogs() {
        guard let storage = storageService else { return }
        let calendar = Calendar.current
        guard let startOfDay = calendar.dateInterval(of: .day, for: Date())?.start else { return }
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        todaysLogs = storage.logsForDateRange(start: startOfDay, end: endOfDay)
    }
}
