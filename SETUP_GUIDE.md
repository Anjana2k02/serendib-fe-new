# Serendib - Detailed Setup Guide

This guide will help you set up and run the Serendib Flutter application from scratch.

## Step 1: Install Flutter

### Windows
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract the zip file to a location (e.g., `C:\src\flutter`)
3. Add Flutter to PATH:
   - Search for "Environment Variables" in Windows
   - Edit PATH variable
   - Add `C:\src\flutter\bin`
4. Run `flutter doctor` to verify installation

<!-- skmswd -->
### macOS
```bash
# Using Homebrew
brew install --cask flutter

# Or download from https://flutter.dev/docs/get-started/install/macos
```

### Linux
```bash
# Download and extract Flutter
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz
tar xf flutter_linux_3.x.x-stable.tar.xz

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"
```

## Step 2: Install Platform Tools

### For Android Development
1. **Install Android Studio** from https://developer.android.com/studio
2. **Install Android SDK**:
   - Open Android Studio
   - Go to Settings > Appearance & Behavior > System Settings > Android SDK
   - Install latest Android SDK
3. **Accept Android Licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

### For iOS Development (macOS only)
1. **Install Xcode** from Mac App Store
2. **Install Xcode Command Line Tools**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```

## Step 3: Verify Flutter Installation

Run Flutter doctor to check if everything is set up correctly:
```bash
flutter doctor -v
```

You should see checkmarks (✓) for:
- Flutter SDK
- Android toolchain (for Android development)
- Xcode (for iOS development, macOS only)
- VS Code or Android Studio
- Connected device (optional at this stage)

## Step 4: Set Up the Serendib Project

1. **Navigate to the project directory**:
   ```bash
   cd d:\Flutter\serendib
   ```

2. **Get Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Verify project structure**:
   ```bash
   flutter analyze
   ```

## Step 5: Configure Platform-Specific Settings

### Android Configuration

Create/update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.serendib">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <application
        android:label="Serendib"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Rest of configuration -->
    </application>
</manifest>
```

Update `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        applicationId "com.example.serendib"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

### iOS Configuration

Update `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide navigation services</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to provide navigation services</string>
```

## Step 6: Run the App

### Using Command Line

1. **List available devices**:
   ```bash
   flutter devices
   ```

2. **Run on a specific device**:
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For Chrome (web)
   flutter run -d chrome
   ```

### Using Android Studio

1. Open the project in Android Studio
2. Select a device from the device dropdown
3. Click the Run button (green play icon)

### Using VS Code

1. Open the project in VS Code
2. Press F5 or go to Run > Start Debugging
3. Select the device when prompted

## Step 7: Testing

### Run Unit Tests
```bash
flutter test
```

### Run Widget Tests
```bash
flutter test integration_test/
```

## Step 8: Building for Release

### Android APK
```bash
# Build APK
flutter build apk --release

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release

# Output location: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release

# Then open Xcode to create archive and submit to App Store
```

## Troubleshooting

### Common Issues

#### "Flutter SDK not found"
- Ensure Flutter is added to your PATH
- Restart your terminal/IDE after adding to PATH

#### "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

#### "CocoaPods not installed" (iOS)
```bash
sudo gem install cocoapods
pod setup
```

#### "Gradle build failed" (Android)
- Clear Flutter cache: `flutter clean`
- Delete `pubspec.lock`
- Run `flutter pub get` again

#### "Xcode build failed" (iOS)
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

### Plugin Issues

If you encounter issues with plugins:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

For iOS specifically:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

## Development Tips

### Hot Reload
- Press `r` in the terminal while app is running
- Or use the hot reload button in your IDE
- Changes to dart files will reflect immediately

### Hot Restart
- Press `R` (capital) in the terminal
- Restarts the app completely
- Use when hot reload doesn't work

### Performance Profiling
```bash
flutter run --profile
```

### Debug Mode
```bash
flutter run --debug
```

### Check App Size
```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

## IDE Setup

### VS Code Extensions
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

### Android Studio Plugins
- Flutter
- Dart

## Next Steps

1. **Customize the app**:
   - Update app name in `pubspec.yaml`
   - Change package name
   - Update app icons

2. **Integrate APIs**:
   - Replace mock authentication with real API
   - Add translation API
   - Integrate map services

3. **Add features**:
   - Implement QR scanning
   - Add AR/VR capabilities
   - Connect backend services

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Provider Package](https://pub.dev/packages/provider)
- [Flutter Community](https://flutter.dev/community)

## Support

If you encounter any issues:
1. Check Flutter doctor: `flutter doctor -v`
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Check GitHub issues
4. Ask on Stack Overflow with the `flutter` tag

Happy coding! 🚀
