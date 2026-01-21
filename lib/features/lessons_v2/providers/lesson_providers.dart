import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/lesson_models.dart';
import '../repositories/lesson_repository.dart';
import '../models/lesson_attempt_request.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository();
});

final lessonDefinitionProvider =
    FutureProvider.family<LessonDefinition?, String>((ref, lessonId) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.fetchLessonById(lessonId);
});

final moduleLessonsProvider =
    FutureProvider.family<List<LessonDefinition>, String>((ref, moduleId) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.fetchLessonsForModule(moduleId);
});

final recordLessonAttemptProvider =
    FutureProvider.family<int, LessonAttemptRequest>((ref, request) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.recordLessonAttempt(
    lessonId: request.lessonId,
    userId: request.userId,
    markCompleted: request.markCompleted,
  );
});

final completedLessonIdsV2Provider =
    FutureProvider.family<Set<String>, String>((ref, moduleId) async {
  final userId = SupabaseConfig.currentUser?.id;
  if (userId == null) {
    return <String>{};
  }

  final lessons = await ref.watch(moduleLessonsProvider(moduleId).future);
  final lessonIds =
      lessons.map((lesson) => lesson.id).where((id) => id.isNotEmpty).toList();
  if (lessonIds.isEmpty) {
    return <String>{};
  }

  try {
    final response = await SupabaseConfig.client
        .from('lesson_completion')
        .select('lesson_id')
        .eq('user_id', userId)
        .inFilter('lesson_id', lessonIds);

    if (response is! List) {
      return <String>{};
    }

    return response
        .map((row) => row['lesson_id'] as String?)
        .whereType<String>()
        .toSet();
  } catch (e) {
    return <String>{};
  }
});
