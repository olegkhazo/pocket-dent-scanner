# Pocket Dent Scanner

MVP mobile application for PDR (Paintless Dent Repair) dent detection using structured light from a phone screen.

## Product Goal

Test whether a smartphone can act as a portable PDR dent scanner without any external hardware:
- Phone screen = programmable structured-light source
- Front-facing camera = records reflection of screen patterns on painted car panel
- CV pipeline = analyzes stripe distortion to locate probable dents

## Current Milestone

**Milestone 1** — Display structured stripes on the phone while simultaneously recording the reflected stripes from the car panel using the front-facing camera.

## Architecture

Feature-first Flutter architecture with Riverpod state management.

```
lib/
  app/           # App entry, router, theme
  core/
    camera/      # Camera service and configuration
    cv/          # CV pipeline, stripe detection, dent candidates
    light/       # Structured-light pattern renderer
    storage/     # Drift database
    sensors/     # IMU (optional)
  features/
    home/
    scan/        # Scan workflow (presentation/domain/data)
    scan_result/
    scan_history/
    settings/
    debug_lab/   # CV debug visualization
native/
  ios/           # Native OpenCV bridge (when needed)
  android/       # Native OpenCV bridge (when needed)
```

## Supported Platforms

- iOS (primary)
- Android (primary)

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> Requires Flutter 3.x and Dart 3.x.

## Camera Permissions

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is required to scan and record reflected structured-light patterns.</string>
```

**Android** — add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## CV Pipeline

1. Capture front-camera frames during scan
2. Convert to grayscale + contrast normalization
3. Detect reflected structured-light stripes
4. Extract stripe centerlines
5. Estimate normal panel curvature baseline
6. Detect local deviations from baseline
7. Aggregate deviations across frames (temporal)
8. Output dent candidates with confidence scores

See [.cursorrules](.cursorrules) for full specification.

## Known Device Limitations

See [docs/experiments.md](docs/experiments.md) for per-device test results.

## How to Run Tests

```bash
flutter test
```

CV fixture frames: `test/fixtures/cv/`
