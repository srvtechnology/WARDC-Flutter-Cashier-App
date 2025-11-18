---
inclusion: always
---

# Technology Stack

## Framework & Language

- **Flutter** 3.35.7 (managed via FVM)
- **Dart** SDK ^3.8.0
- **Material Design 3** (useMaterial3: true)

## State Management & Architecture

- **GetX** (^4.6.6) - State management, routing, dependency injection
- Pattern: Controller-Service-Model architecture
- Bindings for dependency injection per route

## Key Dependencies

### Networking & API
- **dio** (^5.7.0) - HTTP client with interceptors
- Base URL: `https://wardc.srvtechnology.com/public/api/` (production)
- Dev URL: `https://wardc-dev.srvtechnology.com/public/api/`
- Timeout: 15 seconds
- Content-Type: application/json

### Storage & Caching
- **flutter_secure_storage** (^9.2.2) - Secure token storage
- **shared_preferences** (^2.3.3) - User preferences
- **hive** (^2.2.3) + **hive_flutter** (^1.1.0) - Local database for offline caching

### Device Features
- **image_picker** (^1.1.2) - Camera/gallery access
- **geolocator** (^12.0.0) - GPS location services
- **url_launcher** (^6.3.1) - External links
- **map_launcher** (^3.5.0) - Open maps apps

### UI & Assets
- **native_animated_splash** (^0.0.1+1) - Splash screen
- **flutter_launcher_icons** (^0.14.4) - App icons
- Sierra Leone flag colors: Green (#1EB53A), Blue (#0072C6), White (#FFFFFF)

## Common Commands

```bash
# Run app (use FVM)
fvm flutter run

# Build for Android
fvm flutter build apk --release

# Build for iOS
fvm flutter build ios --release

# Get dependencies
fvm flutter pub get

# Clean build
fvm flutter clean

# Generate launcher icons
fvm flutter pub run flutter_launcher_icons

# Run tests
fvm flutter test

# Analyze code
fvm flutter analyze
```

## Build Configuration

- Min Android SDK: 21
- iOS deployment target: Configured in Xcode
- Multi-platform support: Android, iOS, Web, Windows, Linux, macOS
