import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/services/course_service.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonQuizProgress {
  final bool completed;
  final int? score;

  LessonQuizProgress({this.completed = false, this.score});
}

class LessonQuizProgressNotifier extends StateNotifier<LessonQuizProgress> {
  LessonQuizProgressNotifier() : super(LessonQuizProgress());

  void markCompleted(int score) {
    state = LessonQuizProgress(completed: true, score: score);
  }

  void reset() {
    state = LessonQuizProgress();
  }

  // Safe method to update progress from outside the widget context
  static void updateProgress(WidgetRef ref, int score) {
    try {
      ref.read(lessonQuizProgressProvider.notifier).markCompleted(score);
    } catch (e) {
      // Handle the case where ref might be disposed
      print('Error updating quiz progress: $e');
    }
  }
}

final lessonQuizProgressProvider =
    StateNotifierProvider<LessonQuizProgressNotifier, LessonQuizProgress>(
        (ref) => LessonQuizProgressNotifier());

// Global provider to handle quiz results
class QuizResultNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  QuizResultNotifier() : super({});

  void setQuizResult(String lessonId, Map<String, dynamic> result) {
    state = {...state, lessonId: result};
  }

  Map<String, dynamic>? getQuizResult(String lessonId) {
    return state[lessonId];
  }

  void clearQuizResult(String lessonId) {
    final newState = Map<String, Map<String, dynamic>>.from(state);
    newState.remove(lessonId);
    state = newState;
  }
}

final quizResultProvider = StateNotifierProvider<QuizResultNotifier, Map<String, Map<String, dynamic>>>(
  (ref) => QuizResultNotifier(),
);

// Lesson state management
class LessonState {
  final Map<String, dynamic>? courseContext;
  final bool quizResultChecked;

  LessonState({
    this.courseContext,
    this.quizResultChecked = false,
  });

  LessonState copyWith({
    Map<String, dynamic>? courseContext,
    bool? quizResultChecked,
  }) {
    return LessonState(
      courseContext: courseContext ?? this.courseContext,
      quizResultChecked: quizResultChecked ?? this.quizResultChecked,
    );
  }
}

class LessonStateNotifier extends StateNotifier<LessonState> {
  LessonStateNotifier() : super(LessonState());

  void setCourseContext(Map<String, dynamic>? context) {
    state = state.copyWith(courseContext: context);
  }

  void setQuizResultChecked(bool checked) {
    state = state.copyWith(quizResultChecked: checked);
  }

  void reset() {
    state = LessonState();
  }
}

final lessonStateProvider = StateNotifierProvider<LessonStateNotifier, LessonState>(
  (ref) => LessonStateNotifier(),
);

// Lesson completion data provider
class LessonCompletionData {
  final bool isLastLesson;
  final int completedCount;
  final int totalCount;
  final String? nextLessonTitle;
  final int? nextLessonDuration;
  final String? nextLessonId;
  final List<Map<String, dynamic>> upcomingLessons;
  final String? courseId;
  final Map<String, dynamic>? quizResult;

  LessonCompletionData({
    required this.isLastLesson,
    required this.completedCount,
    required this.totalCount,
    this.nextLessonTitle,
    this.nextLessonDuration,
    this.nextLessonId,
    this.upcomingLessons = const [],
    this.courseId,
    this.quizResult,
  });
}

class LessonCompletionDataNotifier extends StateNotifier<LessonCompletionData?> {
  LessonCompletionDataNotifier() : super(null);

  Future<void> calculateCompletionData(String lessonId, Map<String, dynamic>? courseContext, LessonQuizProgress quizProgress, int totalQuizzes) async {
    if (courseContext == null) {
      state = null;
      return;
    }

    try {
      final courseId = courseContext['courseId'] as String?;
      if (courseId == null) {
        state = null;
        return;
      }

      // Get the complete course data from Supabase
      final courseService = CourseService(Supabase.instance.client);
      final course = await courseService.getCompleteCourse(courseId);

      final currentLessonIndex = courseContext['currentLessonIndex'] as int? ?? 0;
      final currentModuleIndex = courseContext['currentModuleIndex'] as int? ?? 0;
      final totalLessons = courseContext['totalLessons'] as int? ?? 1;

      // Determine if this is the last lesson
      final isLastLesson = currentLessonIndex == totalLessons - 1;

      // Calculate completed count (simplified - assuming 1 lesson completed)
      final completedCount = 1;

      // Get next lesson info
      final nextLessonInfo = _getNextLessonInfo(course, currentModuleIndex, currentLessonIndex);

      // Create quiz result if quiz was completed
      Map<String, dynamic>? quizResult;
      if (quizProgress.completed) {
        quizResult = {
          'score': quizProgress.score,
          'totalQuestions': totalQuizzes,
          'isSuccess': quizProgress.score != null && quizProgress.score! >= totalQuizzes * 0.75,
        };
      }

      state = LessonCompletionData(
        isLastLesson: isLastLesson,
        completedCount: completedCount,
        totalCount: totalLessons,
        nextLessonTitle: nextLessonInfo?['title'],
        nextLessonDuration: nextLessonInfo?['duration'],
        nextLessonId: nextLessonInfo?['id'],
        upcomingLessons: [], // TODO: Get upcoming lessons from course data
        courseId: courseId,
        quizResult: quizResult,
      );
    } catch (e) {
      print('Error calculating completion data: $e');
      state = null;
    }
  }

  Map<String, dynamic>? _getNextLessonInfo(CompleteCourseModel course, int currentModuleIndex, int currentLessonIndex) {
    // Find the current module
    if (currentModuleIndex >= course.modules.length) return null;
    final currentModule = course.modules[currentModuleIndex];

    // Check if there's a next lesson in the current module
    if (currentLessonIndex + 1 < currentModule.lessons.length) {
      final nextLesson = currentModule.lessons[currentLessonIndex + 1];
      return {
        'id': nextLesson.id,
        'title': nextLesson.title,
        'duration': nextLesson.durationMinutes,
      };
    }

    // Check if there's a next module
    if (currentModuleIndex + 1 < course.modules.length) {
      final nextModule = course.modules[currentModuleIndex + 1];
      if (nextModule.lessons.isNotEmpty) {
        final nextLesson = nextModule.lessons.first;
        return {
          'id': nextLesson.id,
          'title': nextLesson.title,
          'duration': nextLesson.durationMinutes,
        };
      }
    }

    return null;
  }

  void clear() {
    state = null;
  }
}

final lessonCompletionDataProvider = StateNotifierProvider<LessonCompletionDataNotifier, LessonCompletionData?>(
  (ref) => LessonCompletionDataNotifier(),
);

// Quiz result handler provider
class QuizResultHandlerNotifier extends StateNotifier<bool> {
  QuizResultHandlerNotifier() : super(false);

  void handleQuizResult(WidgetRef ref, String lessonId) {
    print('\n=== Quiz Result Handler ===');
    print('Processing quiz result for lesson: $lessonId');
    
    final quizResults = ref.read(quizResultProvider);
    print('All quiz results: $quizResults');
    
    final quizResult = quizResults[lessonId];
    print('Quiz result for lesson $lessonId: $quizResult');
    
    if (quizResult != null) {
      // Update quiz progress
      final score = quizResult['score'] as int;
      print('Updating quiz progress with score: $score');
      
      ref.read(lessonQuizProgressProvider.notifier).markCompleted(score);
      
      // Clear the quiz result
      ref.read(quizResultProvider.notifier).clearQuizResult(lessonId);
      print('Quiz result cleared for lesson: $lessonId');
      
      // Mark as handled
      state = true;
      print('Quiz result marked as handled');
    } else {
      print('No quiz result found for lesson: $lessonId');
    }
    print('=== End Quiz Result Handler ===\n');
  }

  void reset() {
    state = false;
  }
}

final quizResultHandlerProvider = StateNotifierProvider.family<QuizResultHandlerNotifier, bool, String>(
  (ref, lessonId) => QuizResultHandlerNotifier(),
);
