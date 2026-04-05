import SwiftUI
import MapKit

struct HistoryView: View {
    @EnvironmentObject var storage: StorageService
    @State private var selectedLog: LocationLog?

    var body: some View {
        Group {
            if storage.logs.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "location.slash",
                    description: Text("Start tracking to see your location history.")
                )
            } else {
                List {
                    ForEach(storage.groupedLogsByDate(), id: \.date) { group in
                        DateSection(date: group.date, logs: group.logs, selectedLog: $selectedLog)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .sheet(item: $selectedLog) { log in
            LogDetailSheet(log: log)
        }
    }
}

// MARK: - Date Section

struct DateSection: View {
    let date: Date
    let logs: [LocationLog]
    @Binding var selectedLog: LocationLog?

    var body: some View {
        Section(header: Text(date, style: .date)) {
            ForEach(logs) { log in
                LogRow(log: log)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLog = log
                    }
            }
        }
    }
}

// MARK: - Log Row

struct LogRow: View {
    let log: LocationLog

    var body: some View {
        HStack(spacing: 12) {
            // Location pin icon
            Image(systemName: log.isActive ? "location.fill" : "location")
                .font(.title3)
                .foregroundStyle(log.isActive ? .blue : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                // Time range
                Text(timeRangeText)
                    .font(.body)
                    .fontWeight(.medium)

                // Coordinates
                Text(String(format: "%.4f, %.4f", log.latitude, log.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Duration badge
            if let duration = log.duration {
                Text(durationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15), in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: log.startTime)
        if let endTime = log.endTime {
            let end = formatter.string(from: endTime)
            return "\(start) – \(end)"
        }
        return "\(start) – now"
    }

    private var durationText: String {
        guard let duration = log.duration else { return "" }
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - Log Detail Sheet

struct LogDetailSheet: View {
    let log: LocationLog

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mini map
                MiniMapView(coordinate: CLLocationCoordinate2D(latitude: log.latitude, longitude: log.longitude))
                    .frame(height: 250)

                // Details
                VStack(spacing: 16) {
                    DetailRow(icon: "calendar", label: "Date", value: log.startTime.formatted(date: .abbreviated, time: .omitted))
                    DetailRow(icon: "clock", label: "Start", value: log.startTime.formatted(date: .omitted, time: .shortened))
                    if let endTime = log.endTime {
                        DetailRow(icon: "clock.fill", label: "End", value: endTime.formatted(date: .omitted, time: .shortened))
                    } else {
                        DetailRow(icon: "clock.fill", label: "End", value: "Active")
                    }
                    if let duration = log.duration {
                        DetailRow(icon: "timer", label: "Duration", value: formatDuration(duration))
                    }
                    DetailRow(icon: "location", label: "Location", value: String(format: "%.6f, %.6f", log.latitude, log.longitude))
                }
                .padding()
            }
            .navigationTitle("Location Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.body)
    }
}

// MARK: - Mini Map View

struct MiniMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
