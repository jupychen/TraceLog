import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsService

    var body: some View {
        Form {
            // Time Interval Section
            Section("Time Interval") {
                Picker("Check location every", selection: $settings.timeInterval) {
                    ForEach(SettingsService.timePresets, id: \.value) { preset in
                        Text(preset.label).tag(preset.value)
                    }
                }
            } footer: {
                Text("How often the app checks your location. Longer intervals save more battery.")
            }

            // Distance Interval Section
            Section("Distance Interval") {
                Picker("New log when moved", selection: $settings.distanceInterval) {
                    ForEach(SettingsService.distancePresets, id: \.value) { preset in
                        Text(preset.label).tag(preset.value)
                    }
                }
            } footer: {
                Text("Minimum distance to create a new log. Larger distances mean fewer logs.")
            }

            // Tracking Section
            Section("Tracking") {
                Toggle("Enable Location Tracking", isOn: $settings.trackingEnabled)
            } footer: {
                Text("Turn off to pause all location tracking.")
            }

            // About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
