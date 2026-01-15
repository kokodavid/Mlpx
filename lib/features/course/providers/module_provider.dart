import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/features/course/course_models/module_model.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';
import 'package:milpress/features/course/course_models/lesson_quiz_model.dart';
import 'package:milpress/features/user_progress/services/module_progress_bridge.dart';
import 'package:milpress/features/user_progress/services/user_progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Module Quiz Progress Model
class ModuleQuizProgress {
  final String moduleId;
  final Map<String, LessonQuizScore>
      lessonScores; // lessonId -> LessonQuizScore
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

ModuleModel _buildModuleModel(Map<String, dynamic> moduleData) {
  return ModuleModel.fromJson({
    ...moduleData,
    'duration_minutes': moduleData['duration_minutes'] ?? 0,
    'description': moduleData['description'] ?? 'Untitled Module',
    'lock_message': moduleData['lock_message'] ?? '',
    'course_id': moduleData['course_id'] ?? '',
    'id': moduleData['id'] ?? '',
    'position': moduleData['position'] ?? 0,
    'locked': moduleData['locked'] ?? false,
  });
}

LessonModel _buildLessonModel(
  Map<String, dynamic> lessonData,
  List<LessonQuizModel> quizzes,
) {
  return LessonModel.fromJson({
    ...lessonData,
    'duration_minutes': lessonData['duration_minutes'] ?? 0,
    'title': lessonData['title'] ?? 'Untitled Lesson',
    'description': lessonData['description'] ?? '',
    'module_id': lessonData['module_id'] ?? '',
    'id': lessonData['id'] ?? '',
    'position': lessonData['position'] ?? 0,
    'content': lessonData['content'] ?? '',
    'audio_url': lessonData['audio_url'],
    'video_url': lessonData['video_url'],
    'thumbnail_url': lessonData['thumbnails'],
    'category': lessonData['category'],
    'level': lessonData['level'],
    'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
  });
}

Future<List<LessonModel>> _fetchLessonsForModule(
  SupabaseClient supabase,
  String moduleId,
) async {
  final lessonsResponse = await supabase
      .from('lessons')
      .select()
      .eq('module_id', moduleId)
      .order('position')
      .order('id');

  final lessons =
      await Future.wait((lessonsResponse as List).map((lesson) async {
    final quizzesResponse = await supabase
        .from('lesson_quiz')
        .select()
        .eq('lesson_id', lesson['id']);

    final quizzes = (quizzesResponse as List)
        .map((quiz) => LessonQuizModel.fromJson(quiz))
        .toList();

    return _buildLessonModel(lesson, quizzes);
  }).toList());

  return lessons;
}

Future<ModuleWithLessons?> _fetchModuleWithLessons(
  SupabaseClient supabase,
  String moduleId,
) async {
  try {
    final moduleResponse =
        await supabase.from('modules').select().eq('id', moduleId).single();

    final module = _buildModuleModel(moduleResponse);
    final lessons = await _fetchLessonsForModule(supabase, moduleId);

    return ModuleWithLessons(
      module: module,
      lessons: lessons,
    );
  } catch (e) {
    print('Error fetching module data from Supabase: $e');
    return null;
  }
}

Future<LessonModel?> _fetchLessonById(
  SupabaseClient supabase,
  String lessonId,
) async {
  try {
    final lessonResponse =
        await supabase.from('lessons').select().eq('id', lessonId).single();

    final quizzesResponse =
        await supabase.from('lesson_quiz').select().eq('lesson_id', lessonId);

    final quizzes = (quizzesResponse as List)
        .map((quiz) => LessonQuizModel.fromJson(quiz))
        .toList();

    return _buildLessonModel(lessonResponse, quizzes);
  } catch (e) {
    print('Error fetching lesson data from Supabase: $e');
    return null;
  }
}

// Module Quiz Progress Notifier
class ModuleQuizProgressNotifier extends StateNotifier<ModuleQuizProgress?> {
  ModuleQuizProgressNotifier() : super(null) {}

  void initializeModule(String moduleId) {
    state = ModuleQuizProgress(
      moduleId: moduleId,
      lessonScores: {},
      totalQuizzes: 0,
      completedQuizzes: 0,
      averageScore: 0.0,
      isModuleComplete: false,
    );
  }

  void updateLessonQuizScore(
      String lessonId, String lessonTitle, int score, int totalQuestions) {
    if (state == null) return;

    final newLessonScores =
        Map<String, LessonQuizScore>.from(state!.lessonScores);
    newLessonScores[lessonId] = LessonQuizScore(
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      score: score,
      totalQuestions: totalQuestions,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // Recalculate module statistics
    final totalQuizzes = newLessonScores.values
        .fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
    final completedQuizzes = newLessonScores.values
        .where((score) => score.isCompleted)
        .fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
    final totalScore = newLessonScores.values
        .where((score) => score.isCompleted)
        .fold(0, (sum, lessonScore) => sum + lessonScore.score);
    final averageScore =
        completedQuizzes > 0 ? totalScore / completedQuizzes : 0.0;

    final isModuleComplete = state!.isModuleComplete;

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
      final response = await Supabase.instance.client
          .from('modules')
          .select('course_id')
          .eq('id', moduleId)
          .single();

      return response['course_id'] as String?;
    } catch (e) {
      print('Error getting course ID for module: $e');
      return null;
    }
  }

  Future<String?> _getCourseProgressId(String userId, String courseId) async {
    try {
      final response = await Supabase.instance.client
          .from('course_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .limit(1);

      if (response is List && response.isNotEmpty) {
        return response.first['id'] as String?;
      }
    } catch (e) {
      print('Error fetching course progress ID: $e');
    }
    return null;
  }

  void loadModuleProgress(String moduleId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found, initializing module');
        initializeModule(moduleId);
        return;
      }

      final response = await Supabase.instance.client
          .from('lesson_progress')
          .select(
              'lesson_id, lesson_title, quiz_score, quiz_total_questions, status, completed_at')
          .eq('module_id', moduleId)
          .eq('user_id', user.id)
          .eq('status', 'completed');

      print('\n=== Loading Module Progress (Supabase) ===');
      print('Module ID: $moduleId');
      print('Progress rows found: ${(response as List).length}');

      if (response.isNotEmpty) {
        final lessonScores = <String, LessonQuizScore>{};

        for (final row in response) {
          final data = row as Map<String, dynamic>;
          final lessonId = data['lesson_id'] as String?;
          if (lessonId == null || lessonId.isEmpty) {
            continue;
          }
          final lessonTitle = data['lesson_title'] as String? ?? '';
          final score = (data['quiz_score'] as num?)?.toInt() ?? 0;
          final totalQuestions =
              (data['quiz_total_questions'] as num?)?.toInt() ?? 0;
          final status = data['status'] as String?;
          final completedAtRaw = data['completed_at'] as String?;
          final completedAt =
              completedAtRaw != null ? DateTime.tryParse(completedAtRaw) : null;
          final isCompleted = status == 'completed' || completedAt != null;

          print('  Loading lesson: $lessonId');
          print('    Title: $lessonTitle');
          print('    Score: $score');
          print('    Total Questions: $totalQuestions');
          print('    Is Completed: $isCompleted');

          lessonScores[lessonId] = LessonQuizScore(
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            score: score,
            totalQuestions: totalQuestions,
            isCompleted: isCompleted,
            completedAt: completedAt,
          );
        }

        // Recalculate module statistics
        final totalQuizzes = lessonScores.values
            .fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
        final completedQuizzes = lessonScores.values
            .where((score) => score.isCompleted)
            .fold(0, (sum, lessonScore) => sum + lessonScore.totalQuestions);
        final totalScore = lessonScores.values
            .where((score) => score.isCompleted)
            .fold(0, (sum, lessonScore) => sum + lessonScore.score);
        final averageScore =
            completedQuizzes > 0 ? totalScore / completedQuizzes : 0.0;
        final moduleData = await _getModuleData(moduleId);
        final isModuleComplete = moduleData == null
            ? false
            : moduleData.lessons.every(
                (lesson) => lessonScores[lesson.id]?.isCompleted == true,
              );

        state = ModuleQuizProgress(
          moduleId: moduleId,
          lessonScores: lessonScores,
          totalQuizzes: totalQuizzes,
          completedQuizzes: completedQuizzes,
          averageScore: averageScore,
          isModuleComplete: isModuleComplete,
        );

        print(
            'Loaded module quiz progress from Supabase for module: $moduleId');
        print('Lesson scores loaded: ${lessonScores.length}');
        print('Total quizzes: $totalQuizzes');
        print('Completed quizzes: $completedQuizzes');
        print('Average score: ${averageScore.toStringAsFixed(2)}');
        print('Module complete: $isModuleComplete');
      } else {
        print('No Supabase progress found, initializing module');
        initializeModule(moduleId);
      }
      print('=====================================\n');
    } catch (e) {
      print('Error loading module quiz progress from Supabase: $e');
      initializeModule(moduleId);
    }
  }

  void saveModuleProgress() async {
    if (state == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found, skipping module progress save');
        return;
      }

      final moduleId = state!.moduleId;
      final courseId = await _getCourseIdForModule(moduleId);
      final courseProgressId = courseId != null
          ? await _getCourseProgressId(user.id, courseId)
          : null;
      final now = DateTime.now();

      print('\n=== Saving Module Progress (Supabase) ===');
      print('Module ID: $moduleId');
      print('Lesson scores count: ${state!.lessonScores.length}');

      for (final entry in state!.lessonScores.entries) {
        final lessonId = entry.key;
        final lessonScore = entry.value;
        if (!lessonScore.isCompleted) {
          continue;
        }

        print('  Saving lesson: $lessonId');
        print('    Title: ${lessonScore.lessonTitle}');
        print('    Score: ${lessonScore.score}');
        print('    Total Questions: ${lessonScore.totalQuestions}');
        print('    Is Completed: ${lessonScore.isCompleted}');

        final existing = await Supabase.instance.client
            .from('lesson_progress')
            .select('id')
            .eq('user_id', user.id)
            .eq('lesson_id', lessonId)
            .limit(1);

        final completedAt = lessonScore.completedAt ?? now;
        final data = <String, dynamic>{
          'id': (existing is List && existing.isNotEmpty)
              ? existing.first['id']
              : const Uuid().v4(),
          'user_id': user.id,
          'lesson_id': lessonId,
          'module_id': moduleId,
          'course_progress_id': courseProgressId,
          'status': 'completed',
          'completed_at': completedAt.toIso8601String(),
          'quiz_score': lessonScore.score,
          'quiz_total_questions': lessonScore.totalQuestions,
          'quiz_attempted_at': completedAt.toIso8601String(),
          'lesson_title': lessonScore.lessonTitle,
          'created_at': completedAt.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        await Supabase.instance.client
            .from('lesson_progress')
            .upsert(data, onConflict: 'user_id,lesson_id');
      }

    
    } catch (e) {
      print('Error saving module quiz progress: $e');
    }
  }

  Future<ModuleWithLessons?> _getModuleData(String moduleId) async {
    return _fetchModuleWithLessons(Supabase.instance.client, moduleId);
  }

  void clearModuleProgress(String moduleId) async {
    try {
      state = null;
      print('Cleared module quiz progress for module: $moduleId');
    } catch (e) {
      print('Error clearing module quiz progress: $e');
    }
  }
}

// Module Quiz Progress Provider
final moduleQuizProgressProvider = StateNotifierProvider.family<
    ModuleQuizProgressNotifier, ModuleQuizProgress?, String>(
  (ref, moduleId) => ModuleQuizProgressNotifier(),
);

// Provider to find a lesson across all modules
final lessonFromSupabaseProvider =
    FutureProvider.family<LessonModel?, String>((ref, lessonId) async {


  final lesson = await _fetchLessonById(Supabase.instance.client, lessonId);
  

 

  return lesson;
});

// Provider to get a specific module with its lessons and quizzes from Supabase
final moduleFromSupabaseProvider =
    FutureProvider.family<ModuleWithLessons?, String>((ref, moduleId) async {
  final module =
      await _fetchModuleWithLessons(Supabase.instance.client, moduleId);
  if (module == null) {
    return null;
  }

  return module;
});

// Provider to get the current module's lessons
final moduleLessonsProvider =
    Provider.family<List<LessonModel>, String>((ref, moduleId) {
  final moduleAsync = ref.watch(moduleFromSupabaseProvider(moduleId));

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

final completedLessonIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, moduleId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return <String>{};
  }
  try {
    final response = await Supabase.instance.client
        .from('lesson_progress')
        .select('lesson_id')
        .eq('user_id', user.id)
        .eq('module_id', moduleId)
        .eq('status', 'completed');

    if (response is! List) {
      return <String>{};
    }

    return response
        .map((row) => row['lesson_id'] as String?)
        .whereType<String>()
        .toSet();
  } catch (e) {
    print('Error fetching completed lessons for module: $e');
    return <String>{};
  }
});
