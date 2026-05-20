# Uber Trip Analyzer — Flutter/Dart

A Flutter app that intercepts Uber Driver notifications and shows
a **floating popup with Rs/km rate** so you can quickly decide whether to accept a trip.

---

## Features
- 🔔 Reads Uber notifications in the background
- 🧮 Calculates Rs per kilometer automatically
- 💬 Floating draggable popup over the Uber app
- 🟢 Color-coded: Green (good) / Yellow (average) / Red (low)
- 📊 Trip history with stats
- ⚙️ Configurable thresholds and Uber package name

---

## Project Structure

```
lib/
├── main.dart                    # App entry + overlay widget (overlayMain)
├── models/
│   └── trip_model.dart          # TripData, RateCategory
├── screens/
│   ├── home_screen.dart         # Permission setup + last trip
│   └── history_screen.dart      # Trip history + SettingsScreen
├── services/
│   ├── background_service.dart  # Notification listener + parser + overlay launcher
│   └── permission_service.dart  # Permission checks
├── theme/
│   └── app_theme.dart           # Dark theme + colors
└── widgets/
    ├── permission_card.dart     # Permission step card
    └── trip_card.dart           # Reusable trip display card

android/app/src/main/
├── AndroidManifest.xml          # All permissions + service declarations
└── kotlin/com/uberanalyzer/
    └── MainActivity.kt          # Flutter entry point
```

---

## Setup

### Prerequisites
- Flutter SDK 3.x (`flutter --version`)
- Android Studio or VS Code with Flutter extension
- Android phone (API 26+, Android 8.0+)

### Install & Run
```bash
# 1. Get dependencies
flutter pub get

# 2. Connect your phone (USB debugging enabled)
flutter devices

# 3. Run
flutter run

# OR build APK to install manually
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

---

## First-Run Permissions (on your phone)

The app's home screen guides you, but here's where to go manually:

### Permission 1 — Notification Access
```
Settings → Notifications → Notification Access
→ Find "Uber Analyzer" → Enable
```
This lets the app read Uber's trip notification text.

### Permission 2 — Display Over Other Apps
```
Settings → Apps → Uber Analyzer → Display over other apps → Enable
```
OR the app will prompt you automatically with a system dialog.

---

## Customization

### Change Rate Thresholds
In the app: Settings screen (gear icon) → adjust Good/Average sliders.

Or in code (`lib/main.dart` overlay widget):
```dart
if (perKm >= 80)       // Green – Good
else if (perKm >= 50)  // Yellow – Average
else                   // Red – Low
```

### Change Uber Package Name
In Settings screen, or in `lib/services/background_service.dart`:
```dart
const String kUberPackage = 'com.ubercab.driver';
// Other options:
// 'com.ubercab'          — Uber rider app
// 'com.ubercab.eats'     — Uber Eats
```

To find your exact package name:
- Install **Package Name Viewer** from Play Store
- Find Uber Driver in the list → copy the package name

---

## Debugging

### See parsed notification text
```bash
flutter logs | grep UberAnalyzer
```

Or in Android Studio: **Logcat → filter by tag "UberAnalyzer"**

The logs show:
```
[UberAnalyzer] Notification from: com.ubercab.driver
[UberAnalyzer] Title: New trip request
[UberAnalyzer] Text: Rs. 450 · 8.5 km
[UberAnalyzer] Parsed -> price: 450.0 | distance: 8.5 km
```

If price or distance shows 0.0, the notification text format is different — check the log and adjust the regex in `background_service.dart`.

### Test without Uber
You can simulate a notification from Android Studio:
```bash
adb shell cmd notification post -S bigtext -t "UberTest" \
  "UberTest" "New trip: Rs. 600 · 12.5 km"
```
(Change the package filter in background_service.dart to `'UberTest'` temporarily)

---

## How It Works

```
Uber Driver App
    │
    ▼ posts notification
Android System
    │
    ▼ NotificationListenerService (flutter_notification_listener)
background_service.dart  ← runs in background isolate
    │  parses: price + distance km
    │  calculates: Rs/km
    ▼
flutter_overlay_window  ← draws popup on top of all apps
    │
    ▼ overlayMain() in main.dart
OverlayWidget  ← the floating dark card with Rs/km
```

The app **never contacts Uber's servers**. It only reads the notification
text that Uber already sends to your Android notification bar.

---

## Key Flutter Packages

| Package | Purpose |
|---------|---------|
| `flutter_notification_listener` | Read notifications from other apps |
| `flutter_overlay_window` | Draw floating window over all apps |
| `flutter_background_service` | Keep app running in background |
| `shared_preferences` | Store trip history + settings |
| `permission_handler` | Check/request runtime permissions |

---

## Minimum Requirements
- Android 8.0 (API 26) — required for `TYPE_APPLICATION_OVERLAY`
- Flutter 3.x
- Dart 3.x
