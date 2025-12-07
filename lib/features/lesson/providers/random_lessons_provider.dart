import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';

class RandomLessonsService {
  final SupabaseClient _supabase;

  RandomLessonsService(this._supabase);

  Future<List<LessonModel>> getRandomLessons(int count) async {
    try {
      print('[RandomLessonsService] Requesting $count random lessons');
      
      // First, get all lesson IDs to calculate a random offset
      final allLessonsResponse = await _supabase
          .from('lessons')
          .select('id')
          .order('created_at', ascending: false);

      if (allLessonsResponse == null || (allLessonsResponse as List).isEmpty) {
        print('[RandomLessonsService] No lessons found in database');
        return [];
      }

      final allLessons = allLessonsResponse as List;
      final totalLessons = allLessons.length;
      print('[RandomLessonsService] Total lessons in database: $totalLessons');
      
      // Calculate a random offset, but ensure we don't exceed available lessons
      final random = DateTime.now().millisecondsSinceEpoch;
      final maxOffset = totalLessons - count;
      final offset = maxOffset > 0 ? random % maxOffset : 0;
      print('[RandomLessonsService] Random offset: $offset, requesting range: $offset to ${offset + count - 1}');
      
      // Fetch lessons with the random offset
      final response = await _supabase
          .from('lessons')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + count - 1);

      print('[RandomLessonsService] Raw response length: ${(response as List).length}');
      
      final lessons = (response as List)
          .map((lesson) {
            try {
              // Debug logging for thumbnail data
              print('=== Lesson Data Debug ===');
              print('Lesson ID: ${lesson['id']}');
              print('Lesson Title: ${lesson['title']}');
              print('Raw thumbnails field: ${lesson['thumbnails']}');
              print('Thumbnails type: ${lesson['thumbnails'].runtimeType}');
              print('Category: ${lesson['category']}');
              print('Level: ${lesson['level']}');
              print('All lesson keys: ${lesson.keys.toList()}');
              print('========================');
              
              return LessonModel.fromJson({
                ...lesson,
                'duration_minutes': lesson['duration_minutes'] ?? 0,
                'title': lesson['title'] ?? 'Untitled Lesson',
                'description': lesson['description'] ?? '',
                'module_id': lesson['module_id'] ?? '',
                'id': lesson['id'] ?? '',
                'position': lesson['position'] ?? 0,
                'content': lesson['content'] ?? '',
                'audio_url': lesson['audio_url'],
                'video_url': lesson['video_url'],
                'thumbnail_url': lesson['thumbnails'],
                'category': lesson['category'],
                'level': lesson['level'],
                'quizzes': [], // We don't need quizzes for the jump-in section
              });
            } catch (e) {
              print('[RandomLessonsService] Error processing lesson ${lesson['id']}: $e');
              return null;
            }
          })
          .where((lesson) => lesson != null)
          .cast<LessonModel>()
          .toList();

      print('[RandomLessonsService] Processed lessons count: ${lessons.length}');
      
      // Shuffle the results to make them more random
      lessons.shuffle();
      
      final finalLessons = lessons.take(count).toList();
      print('[RandomLessonsService] Final lessons count: ${finalLessons.length}');
      
      return finalLessons;
    } catch (e) {
      throw Exception('Failed to fetch random lessons: $e');
    }
  }

  Future<List<LessonModel>> getRandomLessonsByCategory(String category, int count) async {
    try {
      // First, get all lesson IDs for this category
      final allLessonsResponse = await _supabase
          .from('lessons')
          .select('id')
          .eq('category', category)
          .order('created_at', ascending: false);

      if (allLessonsResponse == null || (allLessonsResponse as List).isEmpty) {
        return [];
      }

      final allLessons = allLessonsResponse as List;
      final totalLessons = allLessons.length;
      
      // Calculate a random offset
      final random = DateTime.now().millisecondsSinceEpoch;
      final offset = random % totalLessons;
      
      // Fetch lessons with the random offset
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false)
          .range(offset, offset + count - 1);

      final lessons = (response as List)
          .map((lesson) => LessonModel.fromJson({
                ...lesson,
                'duration_minutes': lesson['duration_minutes'] ?? 0,
                'title': lesson['title'] ?? 'Untitled Lesson',
                'description': lesson['description'] ?? '',
                'module_id': lesson['module_id'] ?? '',
                'id': lesson['id'] ?? '',
                'position': lesson['position'] ?? 0,
                'content': lesson['content'] ?? '',
                'audio_url': lesson['audio_url'],
                'video_url': lesson['video_url'],
                'thumbnail_url': lesson['thumbnails'],
                'category': lesson['category'],
                'level': lesson['level'],
                'quizzes': [],
              }))
          .toList();

      // Shuffle the results to make them more random
      lessons.shuffle();
      
      return lessons.take(count).toList();
    } catch (e) {
      throw Exception('Failed to fetch random lessons by category: $e');
    }
  }

  Future<List<LessonModel>> getRandomLessonsByLevel(String level, int count) async {
    try {
      // First, get all lesson IDs for this level
      final allLessonsResponse = await _supabase
          .from('lessons')
          .select('id')
          .eq('level', level)
          .order('created_at', ascending: false);

      if (allLessonsResponse == null || (allLessonsResponse as List).isEmpty) {
        return [];
      }

      final allLessons = allLessonsResponse as List;
      final totalLessons = allLessons.length;
      
      // Calculate a random offset
      final random = DateTime.now().millisecondsSinceEpoch;
      final offset = random % totalLessons;
      
      // Fetch lessons with the random offset
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('level', level)
          .order('created_at', ascending: false)
          .range(offset, offset + count - 1);

      final lessons = (response as List)
          .map((lesson) => LessonModel.fromJson({
                ...lesson,
                'duration_minutes': lesson['duration_minutes'] ?? 0,
                'title': lesson['title'] ?? 'Untitled Lesson',
                'description': lesson['description'] ?? '',
                'module_id': lesson['module_id'] ?? '',
                'id': lesson['id'] ?? '',
                'position': lesson['position'] ?? 0,
                'content': lesson['content'] ?? '',
                'audio_url': lesson['audio_url'],
                'video_url': lesson['video_url'],
                'thumbnail_url': lesson['thumbnails'],
                'category': lesson['category'],
                'level': lesson['level'],
                'quizzes': [],
              }))
          .toList();

      // Shuffle the results to make them more random
      lessons.shuffle();
      
      return lessons.take(count).toList();
    } catch (e) {
      throw Exception('Failed to fetch random lessons by level: $e');
    }
  }
}

// Service provider
final randomLessonsServiceProvider = Provider<RandomLessonsService>((ref) {
  final supabase = Supabase.instance.client;
  return RandomLessonsService(supabase);
});

// Provider to get random lessons
final randomLessonsProvider = FutureProvider.family<List<LessonModel>, int>((ref, count) async {
  final service = ref.read(randomLessonsServiceProvider);
  return service.getRandomLessons(count);
});

// Provider to get random lessons by category
final randomLessonsByCategoryProvider = FutureProvider.family<List<LessonModel>, (String, int)>((ref, params) async {
  final service = ref.read(randomLessonsServiceProvider);
  final (category, count) = params;
  return service.getRandomLessonsByCategory(category, count);
});

// Provider to get random lessons by level
final randomLessonsByLevelProvider = FutureProvider.family<List<LessonModel>, (String, int)>((ref, params) async {
  final service = ref.read(randomLessonsServiceProvider);
  final (level, count) = params;
  return service.getRandomLessonsByLevel(level, count);
});

// Provider for jump-in lessons (default 4 random lessons)
final jumpInLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final service = ref.read(randomLessonsServiceProvider);
  return service.getRandomLessons(4);
}); 