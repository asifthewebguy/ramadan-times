# Ramadan Times

A cross-platform Flutter app for the global Muslim community, providing accurate prayer times, Sehri & Iftar countdown timers, a Qibla compass, monthly timetable, and an optional prayer timer with personal tracking.

**Offline-first. Privacy by design. No accounts. No cloud. No tracking.**

---

## Features

- **Sehri & Iftar Countdown** — Large animated ring timer that auto-switches between Sehri (blue) and Iftar (orange) targets
- **Daily Prayer Times** — All 6 prayer times with next prayer highlighted in gold
- **Qibla Compass** — Live compass using device magnetometer with ±3° alignment indicator *(Phase 2)*
- **Monthly Timetable** — Scrollable table of all prayer times for the current month *(Phase 2)*
- **Prayer Timer & Tracker** — Optional timer for salah with daily completion grid and weekly streak *(Phase 3)*
- **Smart Notifications** — Sehri reminder (configurable), Iftar alert, per-prayer notifications *(Phase 2)*
- **11 Calculation Methods** — Muslim World League, Karachi, ISNA, Umm Al-Qura, Dubai, and more
- **12h / 24h format** — Respects user preference

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State | Provider (ChangeNotifier) |
| Prayer Calc | adhan (offline, local) |
| Location | geolocator + geocoding |
| Compass | flutter_compass |
| Notifications | flutter_local_notifications |
| Storage | Hive (prayer log) + SharedPreferences (settings) |
| UI | percent_indicator, Google Fonts (Poppins) |

## Development Roadmap

| Phase | Status | Deliverables |
|-------|--------|-------------|
| Phase 1 — Core MVP | ✅ Complete | Prayer engine, location, countdown, prayer list, settings, nav shell |
| Phase 2 — Extended | 🔜 Next | Monthly timetable, Qibla compass, notifications, onboarding |
| Phase 3 — Prayer Timer | ⏳ Pending | Timer screen, Hive log, daily tracker, weekly streak |
| Phase 4 — Polish | ⏳ Pending | App icon, splash, animations, store prep |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release
```

### Android Requirements
- Min SDK: 21 (Android 5.0+)
- Target SDK: 34 (Android 14)
- Developer Mode must be enabled for symlink support on Windows

## Architecture

```
lib/
├── main.dart                    # App entry, Hive init, Provider setup
├── models/
│   ├── prayer_time_model.dart   # Countdown logic, next prayer detection
│   └── prayer_log_model.dart    # Hive type for daily prayer log
├── services/
│   ├── app_provider.dart        # Main ChangeNotifier state
│   ├── prayer_time_service.dart # adhan wrapper (11 methods, Qibla)
│   ├── location_service.dart    # GPS + geocoding + cache
│   └── notification_service.dart# (Phase 2)
├── screens/
│   ├── home_screen.dart         # Countdown + prayer list
│   ├── settings_screen.dart     # All settings + city search
│   ├── timetable_screen.dart    # (Phase 2)
│   └── qibla_screen.dart        # (Phase 2)
├── widgets/
│   ├── countdown_timer.dart     # Animated ring + Sehri/Iftar chips
│   └── prayer_time_card.dart    # Single prayer row
└── utils/
    ├── theme.dart               # AppColors, AppTheme.dark, text styles
    └── constants.dart           # Keys, method names, Kaaba coords
```

## Privacy

All prayer time calculations are performed locally using the device's GPS coordinates and the `adhan` Dart package. No data is sent to any server. Location data never leaves the device.
