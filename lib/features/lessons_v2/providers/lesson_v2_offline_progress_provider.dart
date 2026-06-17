import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_completion_cache_service.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_offline_progress_service.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_progress_sync_service.dart';

class LessonV2OfflineProgressState {
  final bool isCompleted;
  final bool isSynced;
  final int attemptCount;

  const LessonV2OfflineProgressState({
    this.isCompleted = false,
    this.isSynced = false,
    this.attemptCount = 0,
  });
}

class LessonV2OfflineProgressNotifier
    extends StateNotifier<LessonV2OfflineProgressState> {
  LessonV2OfflineProgressNotifier(this._ref, this.lessonId)
      : super(const LessonV2OfflineProgressState()) {
    _loadProgress();
  }

  final Ref _ref;
  final String lessonId;

  Future<void> _loadProgress() async {
    final service = _ref.read(lessonV2OfflineProgressServiceProvider);
    final record = await service.readProgress(lessonId);
    state = LessonV2OfflineProgressState(
      isCompleted: record != null,
      isSynced: record?.synced ?? false,
      attemptCount: record?.attemptCount ?? 0,
    );
  }

  Future<void> markCompleted() async {
    final service = _ref.read(lessonV2OfflineProgressServiceProvider);
    await service.saveProgress(lessonId);
    await _loadProgress();
    _ref.invalidate(offlineCompletedLessonIdsProvider);
  }
}

final lessonV2OfflineProgressServiceProvider =
    Provider<LessonV2OfflineProgressService>((ref) {
  return LessonV2OfflineProgressService();
});

final lessonV2CompletionCacheServiceProvider =
    Provider<LessonV2CompletionCacheService>((ref) {
  return LessonV2CompletionCacheService();
});

final lessonV2ProgressSyncServiceProvider =
    Provider<LessonV2ProgressSyncService>((ref) {
  return LessonV2ProgressSyncService(
    offlineProgressService: ref.watch(lessonV2OfflineProgressServiceProvider),
  );
});

final lessonV2OfflineProgressProvider = StateNotifierProvider.family<
    LessonV2OfflineProgressNotifier,
    LessonV2OfflineProgressState,
    String>((ref, lessonId) {
  return LessonV2OfflineProgressNotifier(ref, lessonId);
});

final offlineCompletedLessonIdsProvider =
    FutureProvider<Set<String>>((ref) async {
  final service = ref.watch(lessonV2OfflineProgressServiceProvider);
  final ids = await service.listCompletedLessonIds();
  return ids.toSet();
});

final syncOfflineProgressProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(lessonV2ProgressSyncServiceProvider);
  await service.syncPendingProgress();
  ref.invalidate(offlineCompletedLessonIdsProvider);
});

final canAttemptLessonProvider =
    FutureProvider.family<bool, String>((ref, lessonId) async {
  if (lessonId.isEmpty) {
    return false;
  }

  final lesson = await ref.watch(lessonDefinitionProvider(lessonId).future);
  if (lesson == null || lesson.moduleId.isEmpty) {
    return false;
  }

  final orderedLessons =
      await ref.watch(moduleLessonsProvider(lesson.moduleId).future);
  final lessonIndex =
      orderedLessons.indexWhere((candidate) => candidate.id == lessonId);
  if (lessonIndex < 0) {
    return false;
  }
  if (lessonIndex == 0) {
    return true;
  }

  final previousLessonId = orderedLessons[lessonIndex - 1].id;
  final completedIds =
      await ref.watch(completedLessonIdsV2Provider(lesson.moduleId).future);
  return completedIds.contains(previousLessonId);
});
