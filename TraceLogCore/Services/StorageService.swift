import Foundation
import Combine

@available(macOS 10.15, iOS 16.0, *)
@MainActor
class StorageService: ObservableObject {
    @Published var logs: [LocationLog] = []

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("tracelog.json")
        loadLogs()
    }

    // MARK: - CRUD Operations

    func insert(_ log: LocationLog) {
        logs.append(log)
        save()
    }

    func update(_ log: LocationLog) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
            save()
        }
    }

    func closeActiveLog() {
        guard let activeIndex = logs.firstIndex(where: { $0.isActive }) else { return }
        var log = logs[activeIndex]
        log = LocationLog(
            id: log.id,
            startTime: log.startTime,
            endTime: Date(),
            latitude: log.latitude,
            longitude: log.longitude
        )
        update(log)
    }

    func getActiveLog() -> LocationLog? {
        logs.first(where: { $0.isActive })
    }

    // MARK: - Query

    func loadLogs() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logs = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([LocationLog].self, from: data)
            logs = decoded.sorted { $0.startTime > $1.startTime }
        } catch {
            print("Failed to load logs: \(error)")
            logs = []
        }
    }

    func logsForDateRange(start: Date, end: Date) -> [LocationLog] {
        logs.filter { log in
            log.startTime >= start && log.startTime <= end
        }
    }

    func groupedLogsByDate() -> [(date: Date, logs: [LocationLog])] {
        let calendar = Calendar.current
        var groups: [Date: [LocationLog]] = [:]

        for log in logs {
            if let dayStart = calendar.dateInterval(of: .day, for: log.startTime)?.start {
                groups[dayStart, default: []].append(log)
            }
        }

        return groups
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, logs: $0.value) }
    }

    // MARK: - Persistence

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(logs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save logs: \(error)")
        }
    }
}
