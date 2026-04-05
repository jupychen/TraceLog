import SwiftUI
import MapKit
import UIKit

struct HomeView: View {
    @EnvironmentObject var tracker: LocationTracker
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var settings: SettingsService
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            MapView(region: region, logs: tracker.todaysLogs)
                .ignoresSafeArea()

            VStack {
                // Status bar
                HStack {
                    statusIndicator
                    Spacer()
                    settingsLink
                }
                .padding()

                Spacer()

                // Tracking toggle
                trackingControl
                    .padding()
            }
        }
        .navigationTitle("TraceLog")
        .onAppear {
            tracker.inject(storage: storage, settings: settings)
            centerOnLocation()
        }
        .alert("Location Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings", action: openAppSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to use TraceLog.")
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tracker.isTracking ? .green : .gray)
                .frame(width: 10, height: 10)
                .shadow(color: .green, radius: tracker.isTracking ? 6 : 0)

            Text(tracker.isTracking ? "Tracking" : "Paused")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    // MARK: - Tracking Control

    private var trackingControl: some View {
        Button(action: toggleTracking) {
            HStack {
                Image(systemName: tracker.isTracking ? "pause.fill" : "play.fill")
                Text(tracker.isTracking ? "Stop Tracking" : "Start Tracking")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(tracker.isTracking ? .red : .blue, in: Capsule())
        }
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func toggleTracking() {
        if tracker.isTracking {
            tracker.disableTracking()
        } else {
            tracker.enableTracking()
        }
    }

    private func centerOnLocation() {
        if let location = tracker.currentLocation {
            region.center = location.coordinate
        } else if let activeLog = storage.getActiveLog() {
            region.center = CLLocationCoordinate2D(
                latitude: activeLog.latitude,
                longitude: activeLog.longitude
            )
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - MapView Wrapper

struct MapView: UIViewRepresentable {
    let region: MKCoordinateRegion
    let logs: [LocationLog]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard logs.count > 1 else { return }

        let sortedLogs = logs.sorted { $0.startTime < $1.startTime }
        let coordinates = sortedLogs.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
