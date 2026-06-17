import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/providers/connectivity_provider.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/lesson_models.dart';
import '../repositories/lesson_repository.dart';
import '../models/lesson_attempt_request.dart';
import 'lesson_v2_offline_progress_provider.dart';
import 'lesson_v2_download_provider.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository();
});

final lessonDefinitionProvider =
    FutureProvider.family<LessonDefinition?, String>((ref, lessonId) async {
  final offlineLesson =
      await ref.read(offlineLessonV2Provider(lessonId).future);
  if (offlineLesson != null) return offlineLesson;
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.fetchLessonById(lessonId);
});

final moduleLessonsProvider =
    FutureProvider.family<List<LessonDefinition>, String>((ref, moduleId) async {
  final connectivity = ref.watch(connectivityCheckProvider);
  final connectivityResult = await connectivity.checkConnectivity();
  final isOffline = isOfflineResult(connectivityResult);

  if (!isOffline) {
    final repository = ref.watch(lessonRepositoryProvider);
    final remoteLessons = await repository.fetchLessonsForModule(moduleId);
    if (remoteLessons.isNotEmpty) {
      return remoteLessons;
    }
  }

  return _downloadedLessonsForModule(ref, moduleId);
});

Future<List<LessonDefinition>> _downloadedLessonsForModule(
  Ref ref,
  String moduleId,
) async {
  final downloadedIds = await ref.read(downloadedLessonV2IdsProvider.future);
  if (downloadedIds.isEmpty) {
    return <LessonDefinition>[];
  }

  final offlineLessons = await Future.wait(
    downloadedIds.map((id) => ref.read(offlineLessonV2Provider(id).future)),
  );
  return offlineLessons
      .whereType<LessonDefinition>()
      .where((lesson) => lesson.moduleId == moduleId)
      .toList(growable: false)
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
}

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

    final remoteIds = response
        .map((row) => row['lesson_id'] as String?)
        .whereType<String>()
        .toSet();
    final completionCache = ref.read(lessonV2CompletionCacheServiceProvider);
    await completionCache.saveCompletedLessonIds(moduleId, remoteIds);
    final offlineIds = await ref.watch(offlineCompletedLessonIdsProvider.future);
    return {...remoteIds, ...offlineIds.intersection(lessonIds.toSet())};
  } catch (e) {
    final completionCache = ref.read(lessonV2CompletionCacheServiceProvider);
    final cachedRemoteIds = await completionCache.readCompletedLessonIds(
      moduleId,
    );
    final offlineIds = await ref.watch(offlineCompletedLessonIdsProvider.future);
    final moduleLessonIds = lessonIds.toSet();
    return {
      ...cachedRemoteIds.intersection(moduleLessonIds),
      ...offlineIds.intersection(moduleLessonIds),
    };
  }
});
