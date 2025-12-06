# Shinepara Flutter App

A skincare e-commerce mobile app for iOS and Android.

## Setup Instructions

### Step 1: Generate Full Platform Files

Before building with Codemagic, you need to generate the complete Flutter platform structure. Run this command in the `shinepara_app` directory on a machine with Flutter installed:

```bash
cd shinepara_app
flutter create . --platforms=android,ios
```

This will generate all necessary Xcode and Gradle files while preserving your existing Dart code.

### Step 2: Configure for Codemagic

1. **Push to GitHub** with the generated platform files

2. **Android Signing (for Google Play)**:
   - Create a keystore: `keytool -genkey -v -keystore shinepara-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shinepara`
   - Upload the keystore to Codemagic under Code Signing → Android
   - Name the reference `shinepara_keystore`

3. **iOS Signing (for App Store)**:
   - Connect your Apple Developer account in Codemagic
   - Set up automatic code signing

4. **Update codemagic.yaml**:
   - Change `your-email@example.com` to your actual email
   - Configure Google Play and App Store publishing if needed

### Step 3: Build

Codemagic will automatically build when you push to the `main` branch, or you can trigger builds manually.

## API Configuration

The app connects to: `https://shine-flutter-doc--nabltmnmr.replit.app`

To change the API URL, edit `lib/services/providers.dart`:
```dart
const String apiBaseUrl = 'https://your-domain.com';
```

## Features

- Product catalog with categories and brands
- AI-powered skincare recommendations
- Shopping cart and checkout (COD only)
- Customer authentication
- Order tracking with notifications
- Wishlist
- Full Arabic RTL support

## Package ID

- Android: `com.shinepara.app`
- iOS: `com.shinepara.app`
