# IrriTrack Mobile - Quick Start Guide

## Getting Started in 5 Minutes

### 1. Install Flutter
If you don't have Flutter installed:
- Download from: https://docs.flutter.dev/get-started/install
- Add Flutter to your PATH
- Run `flutter doctor` to verify installation

### 2. Setup the Project
```bash
cd irritrack_mobile
flutter pub get
```

### 3. Run the App
```bash
# For Android emulator/device
flutter run

# For iOS simulator (Mac only)
flutter run -d ios

# For web (testing only)
flutter run -d chrome
```

### 4. Login
Use the default credentials:
- **Email**: admin@thriveoutdoor.com
- **Password**: temp1234

### 5. Explore Features

#### As a Manager:
1. Tap "Repair Items" to set prices for repair items
2. Tap "Properties" → + button to create a new property
3. Tap "Users" → + button to create a technician account
4. Tap "Assign Inspections" to assign work to technicians

#### As a Technician:
1. Logout and login with a technician account
2. Tap "My Assigned Inspections" to see your work
3. Tap "Start/Continue Inspection" to begin work
4. Walk through zones and add repairs
5. Submit when complete

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build APK for Android
flutter build apk

# Clean build files
flutter clean

# Check for issues
flutter doctor

# Format code
flutter format .
```

## Troubleshooting

### Issue: "SDK not found"
**Solution**: Run `flutter doctor` and follow instructions

### Issue: "Gradle build failed" (Android)
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "CocoaPods not installed" (iOS)
**Solution**:
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Issue: App crashes on startup
**Solution**: Check that you have proper permissions for file storage
- Android: Storage permissions in AndroidManifest.xml
- iOS: File access in Info.plist

## File Locations

### Data File Location
- **Android**: `/data/data/com.example.irritrack_mobile/app_flutter/irritrack_data.json`
- **iOS**: `~/Library/Application Support/irritrack_data.json`

### Reset Data
To reset the app to default state:
1. Uninstall the app
2. Reinstall/run again
3. Default admin account will be recreated

## Development Tips

1. **Hot Reload**: Press `r` in the terminal while app is running
2. **Hot Restart**: Press `R` in the terminal while app is running
3. **Enable Debug Mode**: Tap the app title 7 times to enable debug features
4. **View Logs**: Use `flutter logs` or check Android Studio/Xcode console

## Project Structure at a Glance

```
lib/
├── main.dart              # App entry point
├── models/                # Data structures
├── services/              # Business logic
│   ├── storage_service.dart   # Data persistence
│   └── auth_service.dart      # Authentication
└── screens/               # UI screens
    ├── login_screen.dart
    ├── manager/           # Manager features
    └── technician/        # Technician features
```

## Next Steps

- Customize repair items for your business
- Add your team members as users
- Create your first property
- Assign and complete an inspection
- Review the data in the JSON file

## Support

For detailed documentation, see [README.md](README.md)

---

Happy tracking!
