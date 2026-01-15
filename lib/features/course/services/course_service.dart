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

      final modulesById = {for (final module in modules) module.id: module};
      final moduleIds = modulesById.keys.where((id) => id.isNotEmpty).toList();

      List<Map<String, dynamic>> lessonsResponse = [];
      if (moduleIds.isNotEmpty) {
        final lessonsRaw = await _supabase
            .from('lessons')
            .select()
            .inFilter('module_id', moduleIds)
            .order('position')
            .order('id');
        lessonsResponse = (lessonsRaw as List)
            .map((lesson) => Map<String, dynamic>.from(lesson as Map))
            .toList();
      }

      final lessonIds = lessonsResponse
          .map((lesson) => lesson['id'] as String?)
          .whereType<String>()
          .toList();

      final Map<String, List<LessonQuizModel>> quizzesByLessonId = {};
      if (lessonIds.isNotEmpty) {
        final quizzesRaw = await _supabase
            .from('lesson_quiz')
            .select()
            .inFilter('lesson_id', lessonIds);
        final quizzesResponse = (quizzesRaw as List)
            .map((quiz) => Map<String, dynamic>.from(quiz as Map))
            .toList();
        for (final quiz in quizzesResponse) {
          final lessonId = quiz['lesson_id'] as String?;
          if (lessonId == null) continue;
          quizzesByLessonId
              .putIfAbsent(lessonId, () => <LessonQuizModel>[])
              .add(LessonQuizModel.fromJson(quiz));
        }
      }

      final Map<String, List<LessonModel>> lessonsByModuleId = {};
      for (final lesson in lessonsResponse) {
        final moduleId = lesson['module_id'] as String? ?? '';
        if (moduleId.isEmpty) continue;
        final lessonId = lesson['id'] as String? ?? '';
        final quizzes = quizzesByLessonId[lessonId] ?? <LessonQuizModel>[];
        lessonsByModuleId
            .putIfAbsent(moduleId, () => <LessonModel>[])
            .add(LessonModel.fromJson({
          ...lesson,
          'duration_minutes': lesson['duration_minutes'] ?? 0,
          'title': lesson['title'] ?? 'Untitled Lesson',
          'description': lesson['description'] ?? '',
          'module_id': moduleId,
          'id': lessonId,
          'position': lesson['position'] ?? 0,
          'content': lesson['content'] ?? '',
          'audio_url': lesson['audio_url'],
          'video_url': lesson['video_url'],
          'thumbnail_url': lesson['thumbnails'],
          'category': lesson['category'],
          'level': lesson['level'],
          'quizzes': quizzes.map((q) => q.toJson()).toList(),
        }));
      }

      final modulesWithLessons = modules.map((module) {
        final lessons = lessonsByModuleId[module.id] ?? <LessonModel>[];
        debugPrint(
            'Module \u001b[33m\u001b[1m${module.description}\u001b[0m: fetched ${lessons.length} lessons');
        return ModuleWithLessons(
          module: module,
          lessons: lessons,
        );
      }).toList();

      final completeCourse = CompleteCourseModel(
        course: course,
        modules: modulesWithLessons,
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
