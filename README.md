# SchoolPulse - District School Intelligence & Early Warning System

A comprehensive Flutter Web/Mobile application built with Firebase for monitoring attendance, fee collections, and examination schedules while calculating near-real-time operational risk scores across district schools.

## Features

### 📊 District Dashboard
- Real-time risk metrics and composite scores
- Attendance trends with interactive charts
- Fee collection analytics
- Academic performance monitoring
- Active risk alerts with severity levels
- Top risk schools identification

### 🏫 School Management
- Multi-school district support
- School profiles with capacity tracking
- School-specific dashboards
- Risk profiling per school

### 👥 Student Management
- Student enrollment and profiles
- Attendance tracking per student
- Fee balance monitoring
- Academic performance tracking
- Risk level assessment

### 📅 Attendance Tracking
- Daily attendance recording
- Multiple status types (Present, Absent, Late, Excused, Partial)
- Attendance rate calculations
- Trend analysis over time

### 💰 Fee Management
- Multiple fee types (Tuition, Registration, Transport, etc.)
- Payment tracking with partial payments
- Overdue fee identification
- Collection rate analytics

### 📝 Examination System
- Exam scheduling and tracking
- Multiple exam types (Quiz, Midterm, Final, etc.)
- Grade management
- Performance analytics

### ⚠️ Risk Intelligence
- Multi-category risk assessment (Attendance, Fees, Academic, Enrollment)
- Real-time alert generation
- Risk level classification (Low, Medium, High, Critical)
- Composite risk scoring
- Alert resolution workflow

### 🔐 Role-Based Access Control
- Super Administrator (system-wide access)
- District Administrator (district-level access)
- School Administrator (school-level access)
- Teacher (classroom-level access)
- Viewer (read-only access)

## Tech Stack

- **Frontend**: Flutter 3.x (Web, iOS, Android, Desktop)
- **Backend**: Firebase (Auth, Firestore, Cloud Functions)
- **State Management**: Flutter Riverpod
- **Charts**: fl_chart
- **Navigation**: go_router
- **Architecture**: Clean Architecture with Feature-based structure

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models (Freezed + JSON Serializable)
│   ├── user_model.dart
│   ├── student_model.dart
│   ├── attendance_record.dart
│   ├── fee_record.dart
│   ├── exam_record.dart
│   ├── risk_alert.dart
│   └── district_model.dart
├── services/                 # Business logic services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── risk_calculation_service.dart
├── providers/                # Riverpod providers
│   └── app_providers.dart
├── utils/                    # Utilities and helpers
│   ├── app_theme.dart
│   ├── app_router.dart
│   └── app_formatters.dart
├── views/                    # UI screens organized by feature
│   ├── auth/
│   ├── dashboard/
│   ├── schools/
│   ├── students/
│   ├── attendance/
│   ├── fees/
│   ├── exams/
│   ├── risk/
│   └── settings/
└── widgets/                  # Reusable UI components
    └── common_widgets.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.3.0 or higher
- Dart SDK 3.3.0 or higher
- Firebase CLI installed
- A Firebase project

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd schoolpulse
```

2. Install dependencies
```bash
flutter pub get
```

3. Generate code (Freezed, JSON Serializable)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Configure Firebase
```bash
flutterfire configure
```

5. Deploy Firestore rules and indexes
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

6. Run the app
```bash
flutter run -d chrome  # For web
flutter run            # For mobile/desktop
```

## Firebase Setup

### Collections Structure

```
users/{userId}
districts/{districtId}
schools/{schoolId}
students/{studentId}
attendance/{attendanceId}
fees/{feeId}
exams/{examId}
risk_alerts/{alertId}
```

### Security Rules
The `firestore.rules` file implements comprehensive role-based access control with multi-tenant isolation. Deploy with:
```bash
firebase deploy --only firestore:rules
```

### Indexes
Required Firestore indexes are defined in `firestore.indexes.json`. Deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Risk Calculation

The system calculates risk scores using weighted metrics:

| Category | Weight | Thresholds |
|----------|--------|------------|
| Attendance | 35% | Critical: <70%, High: <80%, Medium: <90% |
| Fee Collection | 25% | Critical: <50%, High: <70%, Medium: <85% |
| Academic | 25% | Critical: <50%, High: <60%, Medium: <70% |
| Enrollment | 15% | Critical: <-20%, High: <-10%, Medium: <0% |

Composite Score = Σ(metric × weight)
- Overall Risk: Critical (<60), High (<70), Medium (<80), Low (≥80)

## Development

### Code Generation
```bash
# Watch mode for development
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Web
flutter build web --release

# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Environment Variables

Create a `.env` file for local development:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and code generation
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on GitHub or contact the development team.