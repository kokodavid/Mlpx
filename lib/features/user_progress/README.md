# User Progress Firebase Sync

This module handles syncing user progress data with Firebase/Supabase, including the new module quiz progress functionality.

## Overview

The user progress system now includes **batch Firebase sync** for module quiz progress. When a user completes quizzes in a module:

1. **Quiz Completion**: Progress is saved locally only (fast, no network calls)
2. **Module Complete Screen**: Shows progress summary from local data
3. **Finish Button**: Triggers **single Firebase sync** with complete module data before navigation

## Architecture

### Models
- `CourseProgressModel` - Tracks course-level progress
- `LessonProgressModel` - Tracks lesson-level progress with quiz details
  - Enhanced with `quizTotalQuestions` and `lessonTitle` fields

### Services
- `UserProgressService` - Handles local storage and Firebase sync
- `ModuleProgressBridge` - Bridges ModuleQuizProgress to UserProgress models

### Providers
- `moduleProgressBridgeProvider` - Provides access to the bridge service
- `manualModuleProgressSyncProvider` - Manual trigger for testing

## How It Works

### Improved Sync Flow
When a user completes a module:

1. **Quiz Completions**: `ModuleQuizProgressNotifier.updateLessonQuizScore()` saves locally only
2. **Module Complete Screen**: Displays progress summary from local data
3. **Finish Button**: Triggers `syncModuleProgressToFirebase()` with complete module data
4. **Navigation**: Proceeds to course detail screen after sync

### Data Flow
```
Quiz Completion → Local Save (Hive)
    ↓
Module Complete Screen → Local Data Display
    ↓
Finish Button → Firebase Sync (Complete Module)
    ↓
Course Detail Screen
```

## Benefits of New Approach

### ✅ **Performance**
- **Single Network Request**: One sync call per module instead of per quiz
- **Faster Quiz Completion**: No waiting for network calls during quiz
- **Better Offline Support**: Works without internet until module completion

### ✅ **Data Consistency**
- **Complete Module Context**: Sync happens when we know module is finished
- **Atomic Operation**: All lesson progress synced together
- **Accurate Completion Status**: Module completion confirmed before sync

### ✅ **User Experience**
- **Loading Indicator**: Shows sync progress on Finish button
- **Error Handling**: Graceful fallback if sync fails
- **Success Feedback**: Confirmation when progress is saved

## Usage

### Automatic Sync (Default)
The sync happens automatically when the Finish button is clicked on the module complete screen.

### Manual Sync (Testing)
```dart
// Trigger manual sync for testing
ref.read(manualModuleProgressSyncProvider({
  'moduleId': 'module-123',
  'lessonScores': {
    'lesson-1': {
      'lessonTitle': 'Introduction to Phonics',
      'score': 8,
      'totalQuestions': 10,
      'isCompleted': true,
      'completedAt': '2024-01-01T10:00:00Z',
    }
  },
  'userId': 'user-123',
  'courseId': 'course-456',
}));
```

### Manual Module Sync
```dart
// Sync complete module data
final success = await ref
    .read(moduleQuizProgressProvider(moduleId).notifier)
    .syncModuleProgressToFirebase();
```

## Firebase Schema

### lesson_progress Table
```sql
-- Existing fields
id, user_id, lesson_id, course_progress_id, status, 
started_at, completed_at, video_progress, quiz_score, 
quiz_attempted_at, created_at, updated_at

-- New fields (optional)
quiz_total_questions, lesson_title
```

### course_progress Table
```sql
-- Existing fields
id, user_id, course_id, started_at, completed_at,
current_module_id, current_lesson_id, is_completed,
created_at, updated_at
```

## Error Handling

- **Sync Failures**: Don't break navigation - user can still proceed
- **Offline Scenarios**: Progress saved locally, sync when online
- **Loading States**: Clear feedback during sync process
- **Retry Logic**: Manual sync available for failed operations

## User Interface

### Loading States
- **During Sync**: Loading dialog with "Syncing progress..." message
- **Success**: Green snackbar "Progress saved successfully!"
- **Failure**: Orange snackbar "Progress saved locally. Will sync when online."
- **Error**: Red snackbar with error details

### Navigation
- **Always Proceeds**: Navigation happens regardless of sync status
- **Context Preservation**: Course and module IDs maintained throughout flow

## Testing

To test the Firebase sync:

1. Complete multiple quizzes in a module
2. Navigate to the module complete screen
3. Click "Finish" button
4. Check console logs for sync messages
5. Verify data appears in Supabase dashboard
6. Use `manualModuleProgressSyncProvider` for isolated testing

## Future Enhancements

- **Offline Queue**: Queue sync requests when offline
- **Batch Operations**: Sync multiple modules together
- **Conflict Resolution**: Handle concurrent updates
- **Real-time Status**: Live sync status indicators
- **Retry Mechanisms**: Automatic retry for failed syncs 