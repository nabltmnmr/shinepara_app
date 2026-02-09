# Flutter App Icon & Splash Screen Setup Guide

## Overview
This guide explains how to generate the app icons and splash screen for the Shinepara Flutter app using the logo asset.

## Prerequisites
- Flutter SDK installed
- The project's `pubspec.yaml` already has `flutter_launcher_icons` and `flutter_native_splash` configured

## Step 1: Install Dependencies

Run in your Flutter project directory:

```bash
flutter pub get
```

## Step 2: Generate App Icons

Run the following command to generate app icons for both Android and iOS:

```bash
dart run flutter_launcher_icons
```

This will:
- Generate Android app icons (all sizes including adaptive icons)
- Generate iOS app icons (all required sizes)
- Use the logo at `assets/logo.png`

## Step 3: Generate Splash Screen

Run the following command to generate the native splash screen:

```bash
dart run flutter_native_splash:create
```

This will:
- Configure the native splash screen for Android
- Configure the native splash screen for iOS
- Use a white background with the Shinepara logo centered
- Support dark mode with a dark background

## Step 4: iOS-Specific Setup (if needed)

For iOS, you may need to:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to Runner > General > App Icons and Launch Images
3. Verify the AppIcon is set correctly

## Configuration Details

### App Icons (pubspec.yaml)
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/logo.png"
  min_sdk_android: 21
```

### Splash Screen (pubspec.yaml)
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/logo.png
  color_dark: "#1A1A1A"
  image_dark: assets/logo.png
  android_12:
    color: "#FFFFFF"
    icon_background_color: "#FFFFFF"
    image: assets/logo.png
```

## Troubleshooting

### Icons not updating on Android
- Run `flutter clean` then rebuild
- Uninstall the app and reinstall

### Splash screen not showing
- Make sure to run `dart run flutter_native_splash:create` after any changes
- For iOS, you may need to reset the simulator/device cache

## Logo Files

The logo is stored at:
- `assets/logo.png` - Main logo with transparent background

This logo is used for:
- Android app icon (launcher icon)
- iOS app icon
- Splash screen on both platforms
