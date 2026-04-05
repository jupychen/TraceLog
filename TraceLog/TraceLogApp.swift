import SwiftUI

@main
struct TraceLogApp: App {
    @StateObject private var settingsService = SettingsService()
    @StateObject private var storageService = StorageService()
    @StateObject private var locationTracker = LocationTracker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsService)
                .environmentObject(storageService)
                .environmentObject(locationTracker)
                .onAppear {
                    locationTracker.start()
                }
        }
    }
}

// MARK: - Tab-based ContentView
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "map")
            }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "list.bullet")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
    }
}
