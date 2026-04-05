import Foundation

/// LocationLog model (shared between iOS app and core library)
struct LocationLog: Identifiable, Codable, Equatable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var latitude: Double
    var longitude: Double

    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.latitude = latitude
        self.longitude = longitude
    }

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }
}
