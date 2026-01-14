import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../course_models/course_model.dart';
import '../course_models/module_model.dart';
import '../course_models/lesson_model.dart';
import '../course_models/complete_course_model.dart';
import '../course_models/lesson_quiz_model.dart';

class CourseService {
  final SupabaseClient _supabase;

  CourseService(this._supabase);

  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('locked', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((course) => CourseModel.fromJson(course))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  Future<CourseModel> getCourseById(String id) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', id)
          .single();

      return CourseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch course: $e');
    }
  }

  Future<List<CourseModel>> getCoursesByType(String type) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('type', type)
          .eq('locked', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((course) => CourseModel.fromJson(course))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses by type: $e');
    }
  }

  Future<Map<String, List<CourseModel>>> getCoursesByTypes(List<String> types) async {
    try {
      final Map<String, List<CourseModel>> coursesByType = {};
      
      for (final type in types) {
        final courses = await getCoursesByType(type);
        coursesByType[type] = courses;
      }
      
      return coursesByType;
    } catch (e) {
      throw Exception('Failed to fetch courses by types: $e');
    }
  }

  Future<CompleteCourseModel> getCompleteCourse(String courseId) async {
    try {
      debugPrint('Fetching course data for $courseId');
      final courseResponse = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .eq('locked', false)
          .single();
      
      final course = CourseModel.fromJson(courseResponse);
      debugPrint('Fetched course: ${course.title}');

      final modulesResponse = await _supabase
          .from('modules')
          .select()
          .eq('course_id', courseId)
          .eq('locked', false)
          .order('position');

      final modules = (modulesResponse as List)
          .map((module) => ModuleModel.fromJson({
                ...module,
                'duration_minutes': module['duration_minutes'] ?? 0,
                'description': module['description'] ?? 'Untitled Module',
                'lock_message': module['lock_message'] ?? '',
                'course_id': module['course_id'] ?? courseId,
                'id': module['id'] ?? '',
                'position': module['position'] ?? 0,
                'locked': module['locked'] ?? false,
              }))
          .toList();
      debugPrint('Fetched ${modules.length} modules');

      // Fetch lessons for each module
      final modulesWithLessons = await Future.wait(
        modules.map((module) async {
          try {
            final lessonsResponse = await _supabase
                .from('lessons')
                .select()
                .eq('module_id', module.id)
                .order('position')
                .order('id');

            final lessons =
                await Future.wait((lessonsResponse as List).map((lesson) async {
              // Fetch quizzes for this lesson
              final quizzesResponse = await _supabase
                  .from('lesson_quiz')
                  .select()
                  .eq('lesson_id', lesson['id']);
              final quizzes = (quizzesResponse as List)
                  .map((quiz) => LessonQuizModel.fromJson(quiz))
                  .toList();
              
              // Debug logging for quiz data
              debugPrint('Lesson ${lesson['title']}: fetched ${quizzes.length} quizzes');
              for (int i = 0; i < quizzes.length; i++) {
                final quiz = quizzes[i];
                debugPrint('  Quiz $i: ${quiz.stage} - ${quiz.questionType}');
              }
              
              return LessonModel.fromJson({
                ...lesson,
                'duration_minutes': lesson['duration_minutes'] ?? 0,
                'title': lesson['title'] ?? 'Untitled Lesson',
                'description': lesson['description'] ?? '',
                'module_id': lesson['module_id'] ?? module.id,
                'id': lesson['id'] ?? '',
                'position': lesson['position'] ?? 0,
                'content': lesson['content'] ?? '',
                'audio_url': lesson['audio_url'],
                'video_url': lesson['video_url'],
                'thumbnail_url': lesson['thumbnails'],
                'category': lesson['category'],
                'level': lesson['level'],
                'quizzes': quizzes.map((q) => q.toJson()).toList(),
              });
            }).toList());
            debugPrint(
                'Module [33m[1m${module.description}[0m: fetched ${lessons.length} lessons');

            return ModuleWithLessons(
              module: module,
              lessons: lessons,
            );
          } catch (e) {
            debugPrint('Error fetching lessons for module ${module.description}: $e');
            return ModuleWithLessons(
              module: module,
              lessons: [],
            );
          }
        }),
      );

      // Filter out any modules that failed to load lessons
      final validModulesWithLessons = modulesWithLessons.where((mwl) => mwl.lessons.isNotEmpty).toList();
      debugPrint('Found ${validModulesWithLessons.length} valid modules with lessons');

      final completeCourse = CompleteCourseModel(
        course: course,
        modules: validModulesWithLessons,
        lastUpdated: DateTime.now(),
      );

      return completeCourse;
    } catch (e) {
      debugPrint('Error fetching complete course data: $e');
      // Log the full error stack trace for debugging
      debugPrint('Error details: ${e.toString()}');
      throw Exception('Failed to fetch complete course data: $e');
    }
  }
}
