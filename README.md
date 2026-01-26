# Irrigation Automated Flow

A Flutter-based mobile application for irrigation field service management. Converted from the original Python CLI application.

## Overview

Irrigation Automated Flow Mobile is a comprehensive field service management application designed for THRIVE Outdoor Solutions. It enables managers and technicians to coordinate irrigation system inspections, track repairs, and manage billing.

## Features

### For Managers
- **Repair Items Management**: View, add, update, and delete repair items with pricing
- **Property Management**: Create and view irrigation properties with detailed zone information
- **Inspection Assignment**: Assign inspections to technicians
- **Completed Inspections**: Review completed inspections ready for billing
- **Inspection History**: View all inspection records
- **User Management**: Create and manage technician and manager accounts

### For Technicians
- **My Inspections**: View assigned inspections
- **Start/Continue Inspection**: Work on assigned inspections
- **New Property Inspection**: Create new properties on-the-fly and start inspections
- **Walk Zones**: Navigate through property zones and log repairs
- **My Completed**: Track completed work

## Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- A physical device or emulator

### Setup Steps

1. **Clone or navigate to the project directory**
   ```bash
   cd irritrack_mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Project Structure

```
irritrack_mobile/
├── lib/
│   ├── models/               # Data models
│   │   ├── user.dart
│   │   ├── property.dart
│   │   ├── zone.dart
│   │   ├── inspection.dart
│   │   ├── repair.dart
│   │   └── repair_item.dart
│   ├── services/             # Business logic
│   │   ├── storage_service.dart
│   │   └── auth_service.dart
│   ├── screens/              # UI screens
│   │   ├── login_screen.dart
│   │   ├── manager_home_screen.dart
│   │   ├── technician_home_screen.dart
│   │   ├── manager/          # Manager-specific screens
│   │   └── technician/       # Technician-specific screens
│   └── main.dart             # App entry point
├── pubspec.yaml              # Dependencies
└── README.md
```

## Default Login Credentials

**Manager Account:**
- Email: ``
- Password: ``

## Data Storage

The application uses local JSON file storage via the `path_provider` package. All data is stored in:
- Android: `/data/data/com.example.irritrack_mobile/app_flutter/irritrack_data.json`
- iOS: `~/Library/Application Support/irritrack_data.json`

## Key Workflows

### Manager Workflow
1. Login as manager
2. Create properties with zones
3. Manage repair items and pricing
4. Create technician accounts
5. Assign inspections to technicians
6. Review completed inspections for billing

### Technician Workflow
1. Login as technician
2. View assigned inspections
3. Start inspection
4. Walk through zones
5. Add repairs to each zone
6. Submit inspection when complete

## Features Comparison: Python CLI vs Flutter Mobile

| Feature | Python CLI | Flutter Mobile |
|---------|-----------|----------------|
| Platform | Terminal/Command-line | iOS/Android Mobile |
| UI | Text-based menus | Modern touch UI |
| Storage | JSON file | JSON file (local storage) |
| Authentication | Email/Password | Email/Password |
| User Roles | Manager/Technician | Manager/Technician |
| Property Management | ✓ | ✓ |
| Inspection Workflow | ✓ | ✓ |
| Zone Management | ✓ | ✓ |
| Repair Tracking | ✓ | ✓ |
| Cost Calculation | ✓ | ✓ |
| Offline Support | ✓ | ✓ |

## Future Enhancements

- Cloud synchronization
- Photo attachments for repairs
- GPS location tracking
- PDF report generation
- Push notifications
- Real-time collaboration
- Analytics dashboard
- Calendar integration

## Development

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

### Running Tests
```bash
flutter test
```

## Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **Storage**: Local JSON files (path_provider)
- **Architecture**: MVC pattern
- **State Management**: StatefulWidget

## License

Proprietary - THRIVE Outdoor Solutions

## Support

For issues or questions, contact your system administrator.

---

Converted from Python CLI to Flutter Mobile by Claude AI Assistant
