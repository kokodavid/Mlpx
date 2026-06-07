import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/repositories/lesson_repository.dart';
import 'package:milpress/features/lessons_v2/repositories/lesson_v2_download_repository.dart';

const _checkDownloadStatusError = 'Error checking download status';
const _downloadFailedError = 'Download failed';
const _removeDownloadError = 'Error removing download';

class LessonV2DownloadState {
  final bool isDownloaded;
  final bool isLoading;
  final String? error;

  const LessonV2DownloadState({
    this.isDownloaded = false,
    this.isLoading = false,
    this.error,
  });

  LessonV2DownloadState copyWith({
    bool? isDownloaded,
    bool? isLoading,
    String? error,
  }) {
    return LessonV2DownloadState(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LessonV2DownloadNotifier extends StateNotifier<LessonV2DownloadState> {
  LessonV2DownloadNotifier(this._ref, this.lessonId)
      : super(const LessonV2DownloadState()) {
    _checkDownloadStatus();
  }

  final Ref _ref;
  final String lessonId;

  Future<void> _checkDownloadStatus() async {
    try {
      final repository = _ref.read(lessonV2DownloadRepositoryProvider);
      final isDownloaded = await repository.isDownloaded(lessonId);
      state = state.copyWith(isDownloaded: isDownloaded, error: null);
    } catch (e) {
      state = state.copyWith(error: '$_checkDownloadStatusError: $e');
    }
  }

  Future<void> downloadLesson(LessonDefinition lesson) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(lessonV2DownloadRepositoryProvider);
      await repository.downloadLesson(lesson);
      state = state.copyWith(isDownloaded: true, isLoading: false, error: null);
      _invalidateDownloadedLessonProviders();
    } catch (e) {
      state = state.copyWith(
        isDownloaded: false,
        isLoading: false,
        error: '$_downloadFailedError: $e',
      );
    }
  }

  Future<void> removeDownload() async {
    try {
      final repository = _ref.read(lessonV2DownloadRepositoryProvider);
      await repository.removeDownload(lessonId);
      state = state.copyWith(isDownloaded: false, error: null);
      _invalidateDownloadedLessonProviders();
    } catch (e) {
      state = state.copyWith(error: '$_removeDownloadError: $e');
    }
  }

  Future<LessonDefinition?> getOfflineLesson() async {
    final repository = _ref.read(lessonV2DownloadRepositoryProvider);
    return repository.readLesson(lessonId);
  }

  void _invalidateDownloadedLessonProviders() {
    _ref.invalidate(offlineLessonV2Provider(lessonId));
    _ref.invalidate(downloadedLessonV2IdsProvider);
    _ref.invalidate(downloadedLessonsV2CountProvider);
    _ref.invalidate(downloadedLessonsV2Provider);
  }
}

final lessonV2DownloadRepositoryProvider =
    Provider<LessonV2DownloadRepository>((ref) {
  return LessonV2DownloadRepository(lessonRepository: LessonRepository());
});

final lessonV2DownloadProvider = StateNotifierProvider.family<
    LessonV2DownloadNotifier, LessonV2DownloadState, String>((ref, lessonId) {
  return LessonV2DownloadNotifier(ref, lessonId);
});

final offlineLessonV2Provider =
    FutureProvider.family<LessonDefinition?, String>((ref, lessonId) async {
  final repository = ref.read(lessonV2DownloadRepositoryProvider);
  return repository.readLesson(lessonId);
});

final downloadedLessonV2IdsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(lessonV2DownloadRepositoryProvider);
  return repository.listDownloadedLessonIds();
});

final downloadedLessonsV2CountProvider = FutureProvider<int>((ref) async {
  final ids = await ref.watch(downloadedLessonV2IdsProvider.future);
  return ids.length;
});

final downloadedLessonV2TimeProvider =
    FutureProvider.family<DateTime?, String>((ref, lessonId) async {
  final repository = ref.read(lessonV2DownloadRepositoryProvider);
  return repository.readDownloadedAt(lessonId);
});

final downloadedLessonsV2Provider =
    FutureProvider<List<LessonDefinition>>((ref) async {
  final ids = await ref.watch(downloadedLessonV2IdsProvider.future);
  if (ids.isEmpty) {
    return <LessonDefinition>[];
  }

  final lessons = await Future.wait(
    ids.map((id) => ref.read(offlineLessonV2Provider(id).future)),
  );
  return lessons.whereType<LessonDefinition>().toList(growable: false);
});
