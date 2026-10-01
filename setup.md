# SchoolPulse Setup Guide

## Prerequisites

1. **Flutter SDK** >= 3.3.0
   ```bash
   flutter --version
   ```

2. **Dart SDK** >= 3.3.0 (comes with Flutter)

3. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

4. **IDE**: VS Code with Flutter extension or Android Studio

## Quick Start

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd schoolpulse
flutter pub get
```

### 2. Generate Code

```bash
# Generate Freezed models, JSON serialization, and Riverpod providers
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configure Firebase

```bash
# Initialize Firebase in the project
flutterfire configure

# This will create/update lib/firebase_options.dart with your project config
# Select platforms: Web, Android, iOS, macOS, Windows, Linux as needed
```

### 4. Deploy Firestore Rules & Indexes

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 5. Generate App Icons

```bash
flutter pub run flutter_launcher_icons:main
```

### 6. Run the App

```bash
# Web (Chrome)
flutter run -d chrome

# Web (Edge)
flutter run -d edge

# Android
flutter run -d android

# iOS (requires macOS)
flutter run -d ios

# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## Project Structure

```
schoolpulse/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase config (generated)
│   ├── models/                   # Data models (Freezed)
│   ├── services/                 # Business logic
│   ├── providers/                # Riverpod state management
│   ├── utils/                    # Theme, routing, formatters
│   ├── views/                    # UI screens by feature
│   └── widgets/                  # Reusable components
├── test/                         # Unit and widget tests
├── web/                          # Web-specific files
├── android/                      # Android config
├── ios/                          # iOS config
├── macos/                        # macOS config
├── windows/                      # Windows config
├── linux/                        # Linux config
├── firestore.rules               # Security rules
├── firestore.indexes.json        # Firestore indexes
├── firebase.json                 # Firebase hosting config
└── pubspec.yaml                  # Dependencies
```

## Development Commands

```bash
# Watch mode for code generation
flutter pub run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format .

# Build for production
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: `schoolpulse-<environment>`
3. Enable Authentication: Email/Password
4. Enable Firestore Database (Native mode)
5. Enable Hosting (for web deployment)

### 2. Firestore Collections

The app uses these collections:
- `users` - User profiles with roles
- `districts` - District information
- `schools` - School information
- `students` - Student records
- `attendance` - Attendance records
- `fees` - Fee records
- `exams` - Exam records
- `risk_alerts` - Risk alerts

### 3. Security Rules

Rules are in `firestore.rules` and enforce:
- Multi-tenant isolation by district
- Role-based access control (Super Admin, District Admin, School Admin, Teacher, Viewer)
- Field-level restrictions for sensitive data

### 4. Indexes

Required indexes are in `firestore.indexes.json` for:
- User queries by district/role
- Student queries by school/grade/status
- Attendance queries by school/date/student
- Fee queries by school/due date/status
- Exam queries by school/date/status
- Risk alert queries by district/school/level

## Environment Configuration

### Development

```bash
# Use Firebase emulators for local development
firebase emulators:start
```

Update `lib/main.dart` to connect to emulators:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// For development with emulators
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

### Production

1. Update `.firebaserc` with production project ID
2. Deploy rules and indexes
3. Build and deploy web:
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

## Testing

### Unit Tests

```bash
flutter test test/utils_test.dart
flutter test test/risk_calculation_service_test.dart
```

### Widget Tests

```bash
flutter test test/widget_test.dart
```

### Integration Tests

```bash
flutter test integration_test/
```

## Troubleshooting

### Build Runner Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Config Issues

```bash
# Reconfigure Firebase
flutterfire configure --force
```

### Missing Icons

```bash
flutter pub run flutter_launcher_icons:main
```

### CocoaPods Issues (iOS)

```bash
cd ios
pod install --repo-update
cd ..
```

## CI/CD Pipeline

### GitHub Actions Example

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test

  build_web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: schoolpulse-production
```

## Support

For issues and questions:
- Create a GitHub issue
- Check existing documentation
- Review Firebase and Flutter documentation

## License

MIT License - see LICENSE file for details.