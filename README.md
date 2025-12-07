# Millpress

A Flutter application for learning and assessment.

## Data Persistence Issue Resolution

### Problem
Users were experiencing an issue where assessment results and other app data would persist even after uninstalling and reinstalling the app. This was caused by multiple persistence mechanisms that survive app uninstallation on certain devices/platforms:

1. **Hive Database**: Local NoSQL database that can persist across app uninstallations
2. **SharedPreferences**: Local key-value storage that can survive app removal
3. **Flutter Secure Storage**: Secure storage for biometric settings that persists across installations

### Solution Implemented

#### Option 1: Automatic Data Clearing on Fresh Installation
- **Location**: `lib/splash_screen.dart`
- **Service**: `lib/services/data_clear_service.dart`
- **Functionality**: 
  - Detects fresh app installations using `is_first_run` flag
  - Automatically clears all persistent data on first run
  - Prevents old data from appearing after app reinstallation

#### Option 2: Manual Data Reset
- **Location**: `lib/features/profile/widgets/menu_items_widget.dart`
- **Functionality**:
  - Provides users with "Clear All Data" option in profile menu
  - Shows confirmation dialog before clearing
  - Clears all persistent data and navigates to welcome screen

### Data Clearing Coverage

The solution clears all persistent data including:
- Assessment results (`assessment_results` Hive box)
- Course progress (`course_progress`, `lesson_progress`, `module_progress` Hive boxes)
- Course cache (`complete_courses` Hive box)
- Bookmarks (`bookmarks` Hive box)
- Learning history (`lesson_history` Hive box)
- App settings (SharedPreferences)
- Biometric settings (Flutter Secure Storage)

### Usage

#### For Developers
```dart
// Clear all data
await DataClearService.clearAllData();

// Clear only assessment data
await DataClearService.clearAssessmentData();

// Clear only progress data
await DataClearService.clearProgressData();

// Check if fresh installation
final isFresh = await DataClearService.isFreshInstallation();
```

#### For Users
1. **Automatic**: Data is automatically cleared on fresh installations
2. **Manual**: Go to Profile → Clear All Data → Confirm

### Testing
To test the solution:
1. Complete an assessment
2. Uninstall the app
3. Reinstall the app
4. Verify that no old assessment data appears
5. Verify that the app starts fresh at the welcome screen

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
