import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/features/course/course_models/module_model.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';
import 'package:milpress/features/user_progress/services/module_progress_bridge.dart';
import 'package:milpress/features/user_progress/services/user_progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Module Quiz Progress Model
class ModuleQuizProgress {
  final String moduleId;
  final Map<String, LessonQuizScore> lessonScores; // lessonId -> LessonQuizScore
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final bool isModuleComplete;

  ModuleQuizProgress({
    required this.moduleId,
    required this.lessonScores,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageScore,
    required this.isModuleComplete,
  });

  ModuleQuizProgress copyWith({
    String? moduleId,
    Map<String, LessonQuizScore>? lessonScores,
    int? totalQuizzes,
    int? completedQuizzes,
    double? averageScore,
    bool? isModuleComplete,
  }) {
    return ModuleQuizProgress(
      moduleId: moduleId ?? this.moduleId,
      lessonScores: lessonScores ?? this.lessonScores,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      averageScore: averageScore ?? this.averageScore,
      isModuleComplete: isModuleComplete ?? this.isModuleComplete,
    );
  }
}

class LessonQuizScore {
  final String lessonId;
  final String lessonTitle;
  final int score;
  final int totalQuestions;
  final bool isCompleted;
  final DateTime? completedAt;

  LessonQuizScore({
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.totalQuestions,
    required this.isCompleted,
    this.completedAt,
  });

  LessonQuizScore copyWith({
    String? lessonId,
    String? lessonTitle,
    int? score,
    int? totalQuestions,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return LessonQuizScore(
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Module Quiz Progress Notifier
class ModuleQuizProgressNotifier extends StateNotifier<ModuleQuizProgress?> {
  ModuleQuizProgressNotifier() : super(null) {
    print('\n=== ModuleQuizProgressNotifier Created ===');
    print('Initial state: $state');
    print('=====================================\n');
  }

  void initializeModule(String moduleId) {
    print('\n=== Initializing Module ===');
    print('Module ID: $moduleId');
    print('Previous state: ${state?.moduleId}');
    
    state = ModuleQuizProgress(
      moduleId: moduleId,
      lessonScores: {},
      totalQuizzes: 0,
      completedQuizzes: 0,
      averageScore: 0.0,
      isModuleComplete: false,
    );
    
    print('New state initialized with empty lesson scores');
    print('=====================================\n');
  }

  void updateLessonQuizScore(String lessonId, String lessonTitle, int score, int totalQuestions) {
    if (state == null) return;

    final newLessonScores = Map<String, LessonQuizScore>.from(state!.lessonScores);
    newLessonScores[lessonId] = LessonQuizScore(
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      score: score,
      totalQuestions: totalQuestions,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // Recalculate module statistics
    final totalQuizzes = newLessonScores.values.fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
    final completedQuizzes = newLessonScores.values.where((score) => score.isCompleted).fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
    final totalScore = newLessonScores.values.where((score) => score.isCompleted).fold(0, (sum, lessonScore) => sum + lessonScore.score);
    final averageScore = completedQuizzes > 0 ? totalScore / completedQuizzes : 0.0;

    // Check if module is complete (all lessons have completed quizzes)
    _getModuleData(state!.moduleId).then((module) {
      bool isModuleComplete = false;
      
      if (module != null) {
        final allLessonsHaveQuizzes = module.lessons.every((lesson) => lesson.quizzes.isNotEmpty);
        final allQuizzesCompleted = module.lessons.every((lesson) => 
          lesson.quizzes.isEmpty || newLessonScores.containsKey(lesson.id));
        isModuleComplete = allLessonsHaveQuizzes && allQuizzesCompleted;
      }

      state = state!.copyWith(
        lessonScores: newLessonScores,
        totalQuizzes: totalQuizzes,
        completedQuizzes: completedQuizzes,
        averageScore: averageScore,
        isModuleComplete: isModuleComplete,
      );

      print('\n=== Module Quiz Progress Updated ===');
      print('Module ID: ${state!.moduleId}');
      print('Total quizzes: $totalQuizzes');
      print('Completed quizzes: $completedQuizzes');
      print('Average score: ${averageScore.toStringAsFixed(2)}');
      print('Module complete: $isModuleComplete');
      print('Lesson scores: ${newLessonScores.keys}');
      print('=====================================\n');

      // Save the progress locally only (no automatic Firebase sync)
      saveModuleProgress();
    });
  }

  /// Manual sync method to sync complete module data to Firebase
  Future<bool> syncModuleProgressToFirebase() async {
    if (state == null) {
      print('No module progress to sync');
      return false;
    }

    try {
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found, cannot sync to Firebase');
        return false;
      }

      // Get course ID from module data
      final courseId = await _getCourseIdForModule(state!.moduleId);
      if (courseId == null) {
        print('Course ID not found for module, cannot sync to Firebase');
        return false;
      }

      print('\n=== Syncing Complete Module Progress to Firebase ===');
      print('User ID: ${user.id}');
      print('Course ID: $courseId');
      print('Module ID: ${state!.moduleId}');
      print('Module complete: ${state!.isModuleComplete}');
      print('Lesson scores to sync: ${state!.lessonScores.length}');

      // Create bridge service and trigger sync
      final bridge = ModuleProgressBridge(
        UserProgressService(Supabase.instance.client),
        Supabase.instance.client,
      );

      await bridge.syncCompleteModuleProgress(
        state!.moduleId,
        state!.lessonScores,
        user.id,
        courseId,
        state!.isModuleComplete,
      );

      print('Complete module progress synced to Firebase successfully');
      print('=====================================\n');
      return true;
    } catch (e) {
      print('Error syncing complete module progress to Firebase: $e');
      return false;
    }
  }

  /// Get course ID for a given module
  Future<String?> _getCourseIdForModule(String moduleId) async {
    try {
      if (!Hive.isBoxOpen('complete_courses')) {
        await Hive.openBox<CompleteCourseModel>('complete_courses');
      }

      final box = Hive.box<CompleteCourseModel>('complete_courses');

      for (final course in box.values) {
        for (final module in course.modules) {
          if (module.module.id == moduleId) {
            return course.course.id;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting course ID for module: $e');
      return null;
    }
  }

  void loadModuleProgress(String moduleId) async {
    try {
      if (!Hive.isBoxOpen('module_quiz_progress')) {
        await Hive.openBox<Map>('module_quiz_progress');
      }

      final box = Hive.box<Map>('module_quiz_progress');
      final savedData = box.get(moduleId);

      print('\n=== Loading Module Progress ===');
      print('Module ID: $moduleId');
      print('Saved data found: ${savedData != null}');

      if (savedData != null) {
        final lessonScores = <String, LessonQuizScore>{};
        
        print('Saved data keys: ${savedData.keys}');
        
        for (final entry in savedData.entries) {
          final lessonId = entry.key as String;
          final scoreData = entry.value as Map;
          
          print('  Loading lesson: $lessonId');
          print('    Title: ${scoreData['lessonTitle']}');
          print('    Score: ${scoreData['score']}');
          print('    Total Questions: ${scoreData['totalQuestions']}');
          print('    Is Completed: ${scoreData['isCompleted']}');
          
          lessonScores[lessonId] = LessonQuizScore(
            lessonId: lessonId,
            lessonTitle: scoreData['lessonTitle'] as String? ?? '',
            score: scoreData['score'] as int? ?? 0,
            totalQuestions: scoreData['totalQuestions'] as int? ?? 0,
            isCompleted: scoreData['isCompleted'] as bool? ?? false,
            completedAt: scoreData['completedAt'] != null 
              ? DateTime.parse(scoreData['completedAt'] as String)
              : null,
          );
        }

        // Recalculate module statistics
        final totalQuizzes = lessonScores.values.fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
        final completedQuizzes = lessonScores.values.where((score) => score.isCompleted).fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
        final totalScore = lessonScores.values.where((score) => score.isCompleted).fold(0, (sum, lessonScore) => sum + lessonScore.score);
        final averageScore = completedQuizzes > 0 ? totalScore / completedQuizzes : 0.0;

        state = ModuleQuizProgress(
          moduleId: moduleId,
          lessonScores: lessonScores,
          totalQuizzes: totalQuizzes,
          completedQuizzes: completedQuizzes,
          averageScore: averageScore,
          isModuleComplete: false, // Will be calculated when module data is available
        );

        print('Loaded module quiz progress for module: $moduleId');
        print('Lesson scores loaded: ${lessonScores.length}');
        print('Total quizzes: $totalQuizzes');
        print('Completed quizzes: $completedQuizzes');
        print('Average score: ${averageScore.toStringAsFixed(2)}');
      } else {
        print('No saved data found, initializing module');
        initializeModule(moduleId);
      }
      print('=====================================\n');
    } catch (e) {
      print('Error loading module quiz progress: $e');
      initializeModule(moduleId);
    }
  }

  void saveModuleProgress() async {
    if (state == null) return;

    try {
      if (!Hive.isBoxOpen('module_quiz_progress')) {
        await Hive.openBox<Map>('module_quiz_progress');
      }

      final box = Hive.box<Map>('module_quiz_progress');
      final saveData = <String, Map>{};

      print('\n=== Saving Module Progress ===');
      print('Module ID: ${state!.moduleId}');
      print('Lesson scores count: ${state!.lessonScores.length}');
      
      for (final entry in state!.lessonScores.entries) {
        final lessonId = entry.key;
        final lessonScore = entry.value;
        
        print('  Saving lesson: $lessonId');
        print('    Title: ${lessonScore.lessonTitle}');
        print('    Score: ${lessonScore.score}');
        print('    Total Questions: ${lessonScore.totalQuestions}');
        print('    Is Completed: ${lessonScore.isCompleted}');
        
        saveData[lessonId] = {
          'lessonTitle': lessonScore.lessonTitle,
          'score': lessonScore.score,
          'totalQuestions': lessonScore.totalQuestions,
          'isCompleted': lessonScore.isCompleted,
          'completedAt': lessonScore.completedAt?.toIso8601String(),
        };
      }

      box.put(state!.moduleId, saveData);
      print('Saved module quiz progress for module: ${state!.moduleId}');
      print('Saved data keys: ${saveData.keys}');
      print('=====================================\n');
    } catch (e) {
      print('Error saving module quiz progress: $e');
    }
  }

  Future<ModuleWithLessons?> _getModuleData(String moduleId) async {
    try {
      if (!Hive.isBoxOpen('complete_courses')) {
        await Hive.openBox<CompleteCourseModel>('complete_courses');
      }

      final box = Hive.box<CompleteCourseModel>('complete_courses');

      for (final course in box.values) {
        for (final module in course.modules) {
          if (module.module.id == moduleId) {
            return module;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting module data: $e');
      return null;
    }
  }

  void clearModuleProgress(String moduleId) async {
    try {
      if (!Hive.isBoxOpen('module_quiz_progress')) {
        await Hive.openBox<Map>('module_quiz_progress');
      }

      final box = Hive.box<Map>('module_quiz_progress');
      box.delete(moduleId);
      state = null;
      print('Cleared module quiz progress for module: $moduleId');
    } catch (e) {
      print('Error clearing module quiz progress: $e');
    }
  }
}

// Module Quiz Progress Provider
final moduleQuizProgressProvider = StateNotifierProvider.family<ModuleQuizProgressNotifier, ModuleQuizProgress?, String>(
  (ref, moduleId) => ModuleQuizProgressNotifier(),
);

// Provider to find a lesson across all modules
final lessonFromHiveProvider =
    FutureProvider.family<LessonModel?, String>((ref, lessonId) async {
  try {
    print('\n=== Fetching Lesson from Hive ===');
    print('Lesson ID: $lessonId');

    if (!Hive.isBoxOpen('complete_courses')) {
      await Hive.openBox<CompleteCourseModel>('complete_courses');
    }

    final box = Hive.box<CompleteCourseModel>('complete_courses');

    // Search through all courses and modules to find the lesson
    for (final course in box.values) {
      for (final module in course.modules) {
        for (final lesson in module.lessons) {
          if (lesson.id == lessonId) {
            print('Found lesson: ${lesson.title}');
            print('Module: ${module.module.description}');
            print('Quizzes count: ${lesson.quizzes.length}');

            // Log quiz data
            for (final quiz in lesson.quizzes) {
              print('\nQuiz:');
              print('  ID: ${quiz.id}');
              print('  Question: ${quiz.questionContent}');
              print('  Type: ${quiz.questionType}');
              print('  Options: ${quiz.options}');
            }

            return lesson;
          }
        }
      }
    }

    print('Lesson not found in Hive');
    return null;
  } catch (e) {
    print('Error fetching lesson from Hive: $e');
    rethrow;
  }
});

// Provider to get a specific module with its lessons and quizzes from Hive
final moduleFromHiveProvider =
    FutureProvider.family<ModuleWithLessons?, String>((ref, moduleId) async {
  try {
    print('\n=== Fetching Module from Hive ===');
    print('Module ID: $moduleId');

    if (!Hive.isBoxOpen('complete_courses')) {
      await Hive.openBox<CompleteCourseModel>('complete_courses');
    }

    final box = Hive.box<CompleteCourseModel>('complete_courses');

    // Search through all courses to find the module
    for (final course in box.values) {
      for (final module in course.modules) {
        if (module.module.id == moduleId) {
          print('Found module: ${module.module.description}');
          print('Lessons count: ${module.lessons.length}');

          // Log quiz data for each lesson
          for (final lesson in module.lessons) {
            print('\nLesson: ${lesson.title}');
            print('Quizzes count: ${lesson.quizzes.length}');
            for (final quiz in lesson.quizzes) {
              print('  Quiz: ${quiz.questionContent}');
              print('  Type: ${quiz.questionType}');
            }
          }

          return module;
        }
      }
    }

    print('Module not found in Hive');
    return null;
  } catch (e) {
    print('Error fetching module from Hive: $e');
    rethrow;
  }
});

// Provider to get the current module's lessons
final moduleLessonsProvider =
    Provider.family<List<LessonModel>, String>((ref, moduleId) {
  final moduleAsync = ref.watch(moduleFromHiveProvider(moduleId));

  return moduleAsync.when(
    data: (module) => module?.lessons ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider to get a specific lesson from the current module
final moduleLessonProvider =
    Provider.family<LessonModel?, String>((ref, lessonId) {
  final moduleId =
      lessonId.split('_')[0]; // Assuming lessonId format is "moduleId_lessonId"
  final lessons = ref.watch(moduleLessonsProvider(moduleId));

  try {
    final lesson = lessons.firstWhere(
      (lesson) => lesson.id == lessonId,
    );
    return lesson;
  } catch (e) {
    print('Error finding lesson: $e');
    return null;
  }
});
