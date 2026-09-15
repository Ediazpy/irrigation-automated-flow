# IrriTrack Mobile - Project Structure

## Directory Tree

```
irritrack_mobile/
│
├── lib/                              # Main source code directory
│   │
│   ├── main.dart                     # App entry point
│   │
│   ├── models/                       # Data models (6 files)
│   │   ├── user.dart                 # User model (Manager/Technician)
│   │   ├── property.dart             # Property model with zones
│   │   ├── zone.dart                 # Irrigation zone model
│   │   ├── inspection.dart           # Inspection model
│   │   ├── repair.dart               # Repair record model
│   │   └── repair_item.dart          # Repair item catalog model
│   │
│   ├── services/                     # Business logic layer (2 files)
│   │   ├── storage_service.dart      # JSON file storage & data management
│   │   └── auth_service.dart         # Authentication & login logic
│   │
│   └── screens/                      # UI screens (16 files)
│       │
│       ├── login_screen.dart         # Login page
│       │
│       ├── manager_home_screen.dart  # Manager dashboard
│       ├── manager/                  # Manager feature screens (7 files)
│       │   ├── repair_items_screen.dart
│       │   ├── properties_screen.dart
│       │   ├── create_property_screen.dart
│       │   ├── assign_inspection_screen.dart
│       │   ├── completed_inspections_screen.dart
│       │   ├── inspection_history_screen.dart
│       │   └── users_screen.dart
│       │
│       ├── technician_home_screen.dart  # Technician dashboard
│       └── technician/               # Technician feature screens (5 files)
│           ├── my_inspections_screen.dart
│           ├── start_inspection_screen.dart
│           ├── create_walk_screen.dart
│           ├── my_completed_screen.dart
│           └── do_inspection_screen.dart
│
├── assets/                           # Static assets (future use)
│
├── pubspec.yaml                      # Project dependencies
├── analysis_options.yaml             # Linting rules
│
└── Documentation/
    ├── README.md                     # Full documentation
    ├── QUICKSTART.md                 # Quick start guide
    ├── CONVERSION_SUMMARY.md         # Python to Dart conversion details
    └── PROJECT_STRUCTURE.md          # This file

```

## File Descriptions

### Core Files

| File | Lines | Purpose |
|------|-------|---------|
| `main.dart` | ~60 | App initialization, theme setup, and routing |
| `pubspec.yaml` | ~20 | Dependencies and project configuration |

### Models Layer (Data Structures)

| File | Lines | Purpose |
|------|-------|---------|
| `user.dart` | ~45 | User model with email, password, role, and name |
| `property.dart` | ~60 | Property with address, backflow info, and zones |
| `zone.dart` | ~40 | Zone model with head type and count |
| `inspection.dart` | ~65 | Inspection with repairs, status, and cost |
| `repair.dart` | ~50 | Individual repair record with item and quantity |
| `repair_item.dart` | ~45 | Catalog item with price and category |

**Total Model Code**: ~305 lines

### Services Layer (Business Logic)

| File | Lines | Purpose |
|------|-------|---------|
| `storage_service.dart` | ~250 | JSON file I/O, data persistence, repair item catalog |
| `auth_service.dart` | ~90 | Login, logout, failed attempt tracking |

**Total Service Code**: ~340 lines

### UI Layer - Authentication

| File | Lines | Purpose |
|------|-------|---------|
| `login_screen.dart` | ~180 | Login form with validation and error handling |

### UI Layer - Manager Screens

| File | Lines | Purpose |
|------|-------|---------|
| `manager_home_screen.dart` | ~150 | Dashboard with 6 feature cards |
| `repair_items_screen.dart` | ~160 | CRUD operations for repair items |
| `properties_screen.dart` | ~80 | List all properties with details |
| `create_property_screen.dart` | ~200 | Multi-step form for property creation |
| `assign_inspection_screen.dart` | ~120 | Assign inspection to technician |
| `completed_inspections_screen.dart` | ~60 | View billing-ready inspections |
| `inspection_history_screen.dart` | ~60 | Archive of all inspections |
| `users_screen.dart` | ~130 | User management and creation |

**Total Manager UI Code**: ~960 lines

### UI Layer - Technician Screens

| File | Lines | Purpose |
|------|-------|---------|
| `technician_home_screen.dart` | ~140 | Dashboard with 4 feature cards |
| `my_inspections_screen.dart` | ~60 | View assigned inspections |
| `start_inspection_screen.dart` | ~80 | Select and start inspection |
| `create_walk_screen.dart` | ~180 | Create property and start inspection |
| `my_completed_screen.dart` | ~60 | View completed work |
| `do_inspection_screen.dart` | ~350 | Main inspection workflow with zone walking |

**Total Technician UI Code**: ~870 lines

## Code Statistics Summary

| Layer | Files | Lines | Percentage |
|-------|-------|-------|------------|
| Models | 6 | ~305 | 11% |
| Services | 2 | ~340 | 12% |
| UI - Auth | 1 | ~180 | 6% |
| UI - Manager | 8 | ~960 | 34% |
| UI - Technician | 6 | ~870 | 31% |
| Core | 2 | ~60 | 2% |
| **Total** | **25** | **~2,715** | **100%** |

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                          │
│  (Screens: Login, Manager Dashboard, Tech Dashboard)    │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    Services Layer                        │
│  ┌──────────────────┐       ┌─────────────────────┐    │
│  │  AuthService     │       │  StorageService     │    │
│  │  - login()       │──────▶│  - loadData()       │    │
│  │  - logout()      │       │  - saveData()       │    │
│  │  - currentUser   │       │  - users            │    │
│  └──────────────────┘       │  - properties       │    │
│                              │  - inspections      │    │
│                              │  - repairItems      │    │
│                              └─────────────────────┘    │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                     Models Layer                         │
│  User | Property | Zone | Inspection | Repair | Item    │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                  Data Persistence                        │
│              irritrack_data.json                         │
│        (Device local storage via path_provider)          │
└─────────────────────────────────────────────────────────┘
```

## Screen Navigation Flow

### Manager Flow
```
Login Screen
    │
    ▼
Manager Home
    ├─▶ Repair Items ──▶ View/Edit/Add/Delete
    ├─▶ Properties ──▶ Create Property ──▶ Add Zones
    ├─▶ Assign Inspection ──▶ Select Property & Tech
    ├─▶ Completed Inspections ──▶ View for Billing
    ├─▶ Inspection History ──▶ View All Records
    └─▶ Users ──▶ Create Manager/Technician
```

### Technician Flow
```
Login Screen
    │
    ▼
Technician Home
    ├─▶ My Inspections ──▶ View Assigned
    ├─▶ Start Inspection ──▶ Do Inspection ──▶ Walk Zones ──▶ Add Repairs
    ├─▶ New Property Inspection ──▶ Create Property ──▶ Do Inspection
    └─▶ My Completed ──▶ View Finished Work
```

## Key Components

### Reusable Widgets
- `_MenuCard` (Manager home)
- `_MenuCard` (Technician home)
- Form fields throughout
- List tiles for data display

### State Management
- **StatefulWidget** for screens with user interaction
- **StatelessWidget** for static displays
- `setState()` for local state updates
- Service layer for shared state

### Navigation Pattern
- `Navigator.push()` for forward navigation
- `Navigator.pop()` for back navigation
- `MaterialPageRoute` for screen transitions

## Dependencies

```yaml
dependencies:
  flutter: sdk
  path_provider: ^2.1.1     # Local file storage
  cupertino_icons: ^1.0.2   # iOS-style icons

dev_dependencies:
  flutter_lints: ^2.0.0     # Code quality
```

## Build Targets

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: Minimum iOS 12.0
- **Web**: Supported but not optimized
- **Desktop**: Not configured

---

Total Project Size: ~3,000 lines of production-quality Dart code
