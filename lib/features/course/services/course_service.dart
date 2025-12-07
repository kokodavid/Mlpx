import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../course_models/course_model.dart';
import '../course_models/module_model.dart';
import '../course_models/lesson_model.dart';
import '../course_models/complete_course_model.dart';
import '../course_models/lesson_quiz_model.dart';

class CourseService {
  final SupabaseClient _supabase;
  static const String _completeCourseBox = 'complete_courses';
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  CourseService(this._supabase) {
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isBoxOpen(_completeCourseBox)) {
      await Hive.openBox<CompleteCourseModel>(_completeCourseBox);
      debugPrint('Hive box $_completeCourseBox opened');
      // Clear any invalid cache entries on startup
      await _clearInvalidCacheEntries();
    }
  }

  Future<void> _clearInvalidCacheEntries() async {
    final box = Hive.box<CompleteCourseModel>(_completeCourseBox);
    final keys = box.keys.toList();
    for (final key in keys) {
      final course = box.get(key);
      if (course == null || course.modules.isEmpty) {
        debugPrint('Clearing invalid cache entry for course $key');
        await box.delete(key);
      }
    }
  }

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

  Future<void> printCacheState() async {
    final box = Hive.box<CompleteCourseModel>(_completeCourseBox);
    final keys = box.keys.toList();
    debugPrint('Cache state for $_completeCourseBox:');
    debugPrint('Total cached courses: ${keys.length}');
    
    for (final key in keys) {
      final course = box.get(key);
      if (course != null) {
        final cacheAge = DateTime.now().difference(course.lastUpdated);
        debugPrint('Course ${course.course.title}:');
        debugPrint('  - Last updated: ${course.lastUpdated}');
        debugPrint('  - Cache age: ${cacheAge.inMinutes} minutes');
        debugPrint('  - Modules: ${course.modules.length}');
        debugPrint('  - Total lessons: ${course.modules.fold(0, (sum, m) => sum + m.lessons.length)}');
      }
    }
  }

  Future<CompleteCourseModel> getCompleteCourseWithCache(String courseId) async {
    final box = Hive.box<CompleteCourseModel>(_completeCourseBox);
    
    // Try to get from cache first
    final cachedCourse = box.get(courseId);
    if (cachedCourse != null) {
      final cacheAge = DateTime.now().difference(cachedCourse.lastUpdated);
      debugPrint('Cache hit for course $courseId:');
      debugPrint('  - Cache age: ${cacheAge.inMinutes} minutes');
      debugPrint('  - Modules: ${cachedCourse.modules.length}');
      debugPrint('  - Total lessons: ${cachedCourse.modules.fold(0, (sum, m) => sum + m.lessons.length)}');
      
      // Debug logging for quiz data in cache
      int totalQuizzes = 0;
      for (final module in cachedCourse.modules) {
        for (final lesson in module.lessons) {
          totalQuizzes += lesson.quizzes.length;
          if (lesson.quizzes.isNotEmpty) {
            debugPrint('  - Lesson "${lesson.title}": ${lesson.quizzes.length} quizzes');
          }
        }
      }
      debugPrint('  - Total quizzes in cache: $totalQuizzes');
      
      // If cache is invalid (no modules), clear it
      if (cachedCourse.modules.isEmpty) {
        debugPrint('Clearing invalid cache for course $courseId');
        await box.delete(courseId);
      } else if (cacheAge < _cacheValidityDuration) {
        debugPrint('Using cached data for course $courseId');
        return cachedCourse;
      }
      debugPrint('Cache expired or invalid for course $courseId');
    } else {
      debugPrint('Cache miss for course $courseId');
    }

    // If not in cache or cache expired, fetch from Supabase
    try {
      debugPrint('Fetching fresh data for course $courseId');
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
                .order('position');

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

      // Only cache if we have valid modules with lessons
      if (validModulesWithLessons.isNotEmpty) {
        await box.put(courseId, completeCourse);
        debugPrint('Cached complete course data for ${course.title} with ${validModulesWithLessons.length} modules');
      } else {
        debugPrint('Not caching course ${course.title} as it has no valid modules with lessons');
      }

      return completeCourse;
    } catch (e) {
      debugPrint('Error fetching complete course data: $e');
      // Log the full error stack trace for debugging
      debugPrint('Error details: ${e.toString()}');
      throw Exception('Failed to fetch complete course data: $e');
    }
  }

  Future<void> clearCourseCache(String courseId) async {
    final box = Hive.box<CompleteCourseModel>(_completeCourseBox);
    await box.delete(courseId);
  }

  Future<void> clearAllCourseCache() async {
    final box = Hive.box<CompleteCourseModel>(_completeCourseBox);
    await box.clear();
  }

  Future<CompleteCourseModel> refreshCompleteCourse(String courseId) async {
    debugPrint('Force refreshing course data for $courseId');
    // Clear the cache for this specific course
    await clearCourseCache(courseId);
    // Fetch fresh data
    return await getCompleteCourseWithCache(courseId);
  }
} 