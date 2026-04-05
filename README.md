# TraceLog — Energy-Efficient Location Tracker for iOS

An iOS app that tracks your location history with minimal battery drain and minimal log entries.

## How It Works

The app uses a **smart threshold-based tracking algorithm**:

1. **Time Interval** — checks your location every N seconds (default: 60s)
2. **Distance Interval** — creates a new log only when you've moved more than N meters (default: 100m)

### Tracking Logic

```
Every <timeInterval>:
  Get current position
  Calculate distance from last log
  
  If distance > <distanceInterval>:
    → Close current log (set endTime)
    → Create new log (startTime, lat, lng, no endTime)
  Else:
    → Update endTime on current log (extend it)
```

**Result:** Sitting at a cafe for 2 hours = **1 log**. Walking 500m with 100m threshold = **5 logs**.

## Tech Stack

- **SwiftUI** — declarative UI
- **CoreLocation** — background location tracking
- **MapKit** — map visualization
- **JSON file storage** — lightweight local persistence
- **iOS 16+** — minimum deployment target

## Energy Saving Strategy

1. **Low accuracy GPS** — `kCLLocationAccuracyThreeKilometers` (minimal GPS usage)
2. **Throttled polling** — only checks at configured intervals (no continuous GPS)
3. **Distance-based logging** — only creates logs when you actually move
4. **Background mode** — uses `allowsBackgroundLocationUpdates` with `UIBackgroundModes.location`
5. **Auto-pause** — `pausesLocationUpdatesAutomatically = true`

## Project Structure

```
TraceLog/
├── Package.swift                     # SPM for core library
├── TraceLogCore/                     # Platform-independent code
│   ├── Models/LocationLog.swift      # Data model
│   └── Services/
│       ├── StorageService.swift      # JSON file persistence
│       └── SettingsService.swift     # UserDefaults settings
├── TraceLog/                         # iOS app (requires Xcode)
│   ├── TraceLogApp.swift             # App entry point + TabView
│   ├── Models/LocationLog.swift      # (same as core)
│   ├── Services/
│   │   ├── LocationTracker.swift     # CoreLocation + tracking logic
│   │   ├── StorageService.swift      # (same as core)
│   │   └── SettingsService.swift     # (same as core)
│   ├── Views/
│   │   ├── HomeView.swift            # Map + start/stop toggle
│   │   ├── HistoryView.swift         # Logs grouped by date
│   │   └── SettingsView.swift        # Interval pickers
│   ├── Assets.xcassets/
│   └── Info.plist                    # Permissions + background modes
```

## Build

### Core Library (command line)
```bash
swift build
```

### GitHub Actions (automatic)

Every push to `main` triggers a build. No setup needed — just push.

```bash
git add .
git commit -m "your changes"
git push
```

Check build status: **Actions** tab on your GitHub repo page.

**Free tier:** 2,000 min/month (macOS = 10x multiplier → ~200 real minutes, ~40-60 builds/month).

### Local (requires Xcode)
1. `brew install xcodegen`
2. `xcodegen generate` (creates `.xcodeproj`)
3. Open `TraceLog.xcodeproj` in Xcode
4. Select your iPhone → Build & Run

## Usage

1. **Grant location permission** — "Always Allow" for background tracking
2. **Tap Start Tracking** — begins monitoring your location
3. **View history** — see past logs grouped by date, tap to view on map
4. **Configure settings** — adjust time/distance intervals to balance accuracy vs battery

## Permissions

The app requires:
- **Location When In Use** — basic tracking while app is open
- **Location Always** — background tracking when app is closed
- **Background Mode: Location** — enables tracking in background
# TraceLog
