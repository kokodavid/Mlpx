import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class DataClearService {
  static const List<String> _hiveBoxes = [
    'assessment_results',
    'complete_courses',
    'course_progress',
    'lesson_progress',
    'module_progress',
    'bookmarks',
    'lesson_history',
  ];

  /// Clears all persistent data from the app
  static Future<void> clearAllData() async {
    try {
      developer.log('Starting to clear all persistent data...');

      // Clear all Hive data
      for (final boxName in _hiveBoxes) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          developer.log('Cleared Hive box: $boxName');
        } catch (e) {
          developer.log('Error clearing Hive box $boxName: $e');
          // Continue with other boxes even if one fails
        }
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('Cleared SharedPreferences');

      // Clear Flutter Secure Storage
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      developer.log('Cleared Flutter Secure Storage');

      developer.log('All persistent data cleared successfully');
    } catch (e, stackTrace) {
      developer.log('Error clearing all data: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Clears only assessment-related data
  static Future<void> clearAssessmentData() async {
    try {
      developer.log('Clearing assessment data...');

      // Clear assessment results
      try {
        await Hive.deleteBoxFromDisk('assessment_results');
        developer.log('Cleared assessment_results Hive box');
      } catch (e) {
        developer.log('Error clearing assessment_results box: $e');
      }

      // Clear assessment-related SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest_user');
      developer.log('Cleared assessment-related SharedPreferences');

      developer.log('Assessment data cleared successfully');
    } catch (e, stackTrace) {
      developer.log('Error clearing assessment data: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Clears only progress-related data
  static Future<void> clearProgressData() async {
    try {
      developer.log('Clearing progress data...');

      final progressBoxes = [
        'course_progress',
        'lesson_progress',
        'module_progress',
      ];

      for (final boxName in progressBoxes) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          developer.log('Cleared progress box: $boxName');
        } catch (e) {
          developer.log('Error clearing progress box $boxName: $e');
        }
      }

      developer.log('Progress data cleared successfully');
    } catch (e, stackTrace) {
      developer.log('Error clearing progress data: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Checks if this is a fresh installation
  static Future<bool> isFreshInstallation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_first_run') ?? true;
    } catch (e) {
      developer.log('Error checking fresh installation: $e');
      return true; // Assume fresh installation on error
    }
  }

  /// Marks the app as not a fresh installation
  static Future<void> markAsNotFreshInstallation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_run', false);
      developer.log('Marked app as not fresh installation');
    } catch (e) {
      developer.log('Error marking as not fresh installation: $e');
    }
  }
} 