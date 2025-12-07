import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';

final lessonProvider =
    FutureProvider.family<LessonModel, String>((ref, lessonId) async {
  final supabase = Supabase.instance.client;

  final response =
      await supabase.from('lessons').select().eq('id', lessonId).single();

  return LessonModel.fromJson({
    ...response,
    'duration_minutes': response['duration_minutes'] ?? 0,
    'title': response['title'] ?? 'Untitled Lesson',
    'description': response['description'] ?? '',
    'module_id': response['module_id'] ?? '',
    'id': response['id'] ?? '',
    'position': response['position'] ?? 0,
    'content': response['content'] ?? '',
    'audio_url': response['audio_url'],
    'video_url': response['video_url'],
            'thumbnail_url': response['thumbnails'],
    'category': response['category'],
    'level': response['level'],
  });
});
