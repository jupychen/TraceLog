import Foundation

@MainActor
class SettingsService: ObservableObject {
    /// Time between location checks, in seconds
    @AppStorage("timeInterval") var timeInterval: Double = 60.0 // 1 minute default

    /// Distance in meters that triggers a new log entry
    @AppStorage("distanceInterval") var distanceInterval: Double = 100.0 // 100m default

    /// Whether tracking is enabled
    @AppStorage("trackingEnabled") var trackingEnabled: Bool = true

    /// Preset time intervals (in seconds) for picker
    static let timePresets: [(label: String, value: Double)] = [
        ("30s", 30),
        ("1m", 60),
        ("2m", 120),
        ("5m", 300),
        ("10m", 600),
        ("15m", 900),
    ]

    /// Preset distance intervals (in meters) for picker
    static let distancePresets: [(label: String, value: Double)] = [
        ("25m", 25),
        ("50m", 50),
        ("100m", 100),
        ("200m", 200),
        ("500m", 500),
        ("1km", 1000),
    ]
}
