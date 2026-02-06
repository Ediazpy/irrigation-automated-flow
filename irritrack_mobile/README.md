# IAF App - Irrigation Automated Flow

Commercial Irrigation Management System

## Live Web App

**Access the app at:** https://ediazpy.github.io/irrigation-automated-flow/

### Install on Your Device (PWA)

**iPhone (Safari):**
1. Open Safari and go to https://ediazpy.github.io/irrigation-automated-flow/
2. Tap the Share button (square with arrow)
3. Tap "Add to Home Screen"
4. Name it "IAF App" and tap Add

**Android (Chrome):**
1. Open Chrome and go to https://ediazpy.github.io/irrigation-automated-flow/
2. Tap the menu (3 dots)
3. Tap "Add to Home screen"
4. Name it "IAF App" and tap Add

## Features

### Manager Features
- **Properties**: Manage commercial properties with multiple controllers, zones, and client contacts
- **Scheduling**: Bulk schedule inspections with monthly billing cycles
- **Review**: Review technician inspections, adjust pricing, add labor charges
- **Quotes**: Create professional quotes, send via email/SMS, track status
- **Repair Tasks**: Schedule approved repairs for technicians
- **Reports**: Monthly inspection reports and history
- **Users**: Manage technicians with password reset via security questions
- **Settings**: Company branding, contact info, default terms

### Technician Features
- **My Inspections**: View assigned inspections
- **Start Inspection**: Work through zones, document repairs
- **New Property**: Create property and start inspection
- **My Completed**: View completed work for current month
- **Repair Tasks**: View and complete assigned repair tasks

### Quote Workflow
1. Technician completes inspection and submits for review
2. Manager reviews, adjusts pricing, adds labor/discount
3. Manager sends quote to client via email or SMS
4. Client views quote, signs digitally, approves or rejects
5. Manager schedules approved repairs
6. Technician completes repair tasks

## Security
- Role-based access (Manager vs Technician)
- Client data (signatures, pricing, contact info) is manager-only
- Account lockout after failed login attempts
- Security questions for manager password recovery

## Development

### Prerequisites
- Flutter SDK 3.0+
- Android Studio or VS Code with Flutter extension

### Run Locally
```bash
# Get dependencies
flutter pub get

# Run on Android emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Build for web release
flutter build web --release --base-href "/irrigation-automated-flow/"


Converted from Python CLI to Flutter Mobile by Claude AI Assistant
