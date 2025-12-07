# Changelog

All notable changes to this project will be documented in this file.

## [1.0.5] - 2024-01-XX

### Fixed
- **Data Persistence Issue**: Fixed critical bug where assessment results and app data would persist after app uninstallation and reinstallation
  - Implemented automatic data clearing on fresh installations
  - Added "Clear All Data" option in profile menu for manual reset
  - Created centralized `DataClearService` for comprehensive data management
  - Clears all Hive databases, SharedPreferences, and Flutter Secure Storage
  - Ensures clean app state after reinstallation

### Added
- New `DataClearService` for managing persistent data
- "Clear All Data" functionality in profile menu
- Fresh installation detection and automatic data clearing
- Comprehensive logging for data clearing operations

### Technical Details
- **Hive Database**: Clears `assessment_results`, `complete_courses`, `course_progress`, `lesson_progress`, `module_progress`, `bookmarks`, `lesson_history`
- **SharedPreferences**: Clears all app settings including `is_guest_user` flag
- **Flutter Secure Storage**: Clears biometric settings and secure data
- **Fresh Installation Detection**: Uses `is_first_run` flag to detect new installations

### Testing
- Verified that old assessment data is cleared on fresh installations
- Confirmed guest user navigation works correctly after data clearing
- Tested manual data clearing functionality in profile menu

## [1.0.4] - Previous Release
- Initial release with assessment functionality
- Course management and progress tracking
- Biometric authentication support 