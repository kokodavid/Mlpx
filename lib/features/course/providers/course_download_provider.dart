import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart'
    as lessons_v2;
import 'package:milpress/features/lessons_v2/providers/lesson_v2_download_provider.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_offline_storage_service.dart';

const _checkCourseDownloadStatusError = 'Error checking course download status';
const _courseDownloadFailedError = 'Course download failed';

class CourseV2DownloadState {
  final bool isDownloaded;
  final bool isLoading;
  final bool isError;
  final bool isCancelling;
  final int downloadedBytes;
  final int downloadedLessons;
  final int estimatedTotalBytes;
  final int totalLessons;
  final String? error;

  const CourseV2DownloadState({
    this.isDownloaded = false,
    this.isLoading = false,
    this.isError = false,
    this.isCancelling = false,
    this.downloadedBytes = 0,
    this.downloadedLessons = 0,
    this.estimatedTotalBytes = 0,
    this.totalLessons = 0,
    this.error,
  });

  CourseV2DownloadState copyWith({
    bool? isDownloaded,
    bool? isLoading,
    bool? isError,
    bool? isCancelling,
    int? downloadedBytes,
    int? downloadedLessons,
    int? estimatedTotalBytes,
    int? totalLessons,
    String? error,
  }) {
    return CourseV2DownloadState(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      isCancelling: isCancelling ?? this.isCancelling,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      downloadedLessons: downloadedLessons ?? this.downloadedLessons,
      estimatedTotalBytes: estimatedTotalBytes ?? this.estimatedTotalBytes,
      totalLessons: totalLessons ?? this.totalLessons,
      error: error,
    );
  }
}

class CourseV2DownloadNotifier extends StateNotifier<CourseV2DownloadState> {
  CourseV2DownloadNotifier(this._ref, this.courseId)
      : super(const CourseV2DownloadState()) {
    _checkDownloadStatus();
  }

  final Ref _ref;
  final String courseId;
  final LessonV2OfflineStorageService _offlineStorageService =
      LessonV2OfflineStorageService();
  bool _cancelRequested = false;

  Future<void> _checkDownloadStatus() async {
    try {
      final lessons = await _courseLessons();
      final downloadedBytes = await _downloadedBytesForLessons(lessons);
      final downloadedLessons = await _downloadedLessonCount(lessons);
      final isDownloaded = lessons.isNotEmpty &&
          await _allLessonsDownloaded(lessons.map((lesson) => lesson.id));
      state = state.copyWith(
        isDownloaded: isDownloaded,
        isLoading: false,
        isError: false,
        isCancelling: false,
        downloadedBytes: downloadedBytes,
        downloadedLessons: downloadedLessons,
        estimatedTotalBytes: _estimatedTotalBytes(lessons.length),
        totalLessons: lessons.length,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        isCancelling: false,
        error: '$_checkCourseDownloadStatusError: $e',
      );
    }
  }

  Future<void> downloadCourse() async {
    if (state.isLoading) return;

    _cancelRequested = false;
    state = state.copyWith(
      isLoading: true,
      isError: false,
      isCancelling: false,
      downloadedBytes: 0,
      downloadedLessons: 0,
      error: null,
    );

    try {
      final lessons = await _courseLessons();
      final repository = _ref.read(lessonV2DownloadRepositoryProvider);
      var downloadedBytes = 0;
      var downloadedLessons = 0;

      state = state.copyWith(
        estimatedTotalBytes: _estimatedTotalBytes(lessons.length),
        totalLessons: lessons.length,
      );

      for (final lesson in lessons) {
        if (_cancelRequested) {
          _cancelDownloadState(downloadedBytes, downloadedLessons);
          return;
        }
        await repository.downloadLesson(lesson);
        if (_cancelRequested) {
          _cancelDownloadState(downloadedBytes, downloadedLessons);
          return;
        }
        downloadedBytes += await _lessonDirectorySize(lesson.id);
        downloadedLessons++;
        state = state.copyWith(
          downloadedBytes: downloadedBytes,
          downloadedLessons: downloadedLessons,
        );
        _invalidateLessonDownloadProviders(lesson.id);
      }

      state = state.copyWith(
        isDownloaded: lessons.isNotEmpty,
        isLoading: false,
        isError: false,
        isCancelling: false,
        downloadedBytes: downloadedBytes,
        downloadedLessons: downloadedLessons,
        estimatedTotalBytes: downloadedBytes,
        totalLessons: lessons.length,
        error: null,
      );
      _ref.invalidate(isCourseDownloadedProvider(courseId));
    } catch (e) {
      state = state.copyWith(
        isDownloaded: false,
        isLoading: false,
        isError: true,
        isCancelling: false,
        error: '$_courseDownloadFailedError: $e',
      );
    }
  }

  void cancelDownload() {
    if (!state.isLoading) return;
    _cancelRequested = true;
    state = state.copyWith(isCancelling: true);
  }

  Future<void> removeCourseDownload() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, isError: false, error: null);
    try {
      final lessons = await _courseLessons();
      final repository = _ref.read(lessonV2DownloadRepositoryProvider);
      for (final lesson in lessons) {
        await repository.removeDownload(lesson.id);
        _invalidateLessonDownloadProviders(lesson.id);
      }
      state = state.copyWith(
        isDownloaded: false,
        isLoading: false,
        isError: false,
        isCancelling: false,
        downloadedBytes: 0,
        downloadedLessons: 0,
        error: null,
      );
      _ref.invalidate(isCourseDownloadedProvider(courseId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        isCancelling: false,
        error: 'Error removing course download: $e',
      );
    }
  }

  Future<List<LessonDefinition>> _courseLessons() async {
    final completeCourse =
        await _ref.read(completeCourseProvider(courseId).future);
    final lessonGroups = await Future.wait(
      completeCourse.modules.map(
        (module) => _ref.read(
          lessons_v2.moduleLessonsProvider(module.module.id).future,
        ),
      ),
    );
    return lessonGroups
        .expand((lessons) => lessons)
        .where((lesson) => lesson.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> _allLessonsDownloaded(Iterable<String> lessonIds) async {
    for (final lessonId in lessonIds) {
      final offlineLesson =
          await _ref.read(offlineLessonV2Provider(lessonId).future);
      if (offlineLesson == null) {
        return false;
      }
    }
    return true;
  }

  Future<int> _downloadedBytesForLessons(List<LessonDefinition> lessons) async {
    var totalBytes = 0;
    for (final lesson in lessons) {
      final offlineLesson =
          await _ref.read(offlineLessonV2Provider(lesson.id).future);
      if (offlineLesson != null) {
        totalBytes += await _lessonDirectorySize(lesson.id);
      }
    }
    return totalBytes;
  }

  Future<int> _downloadedLessonCount(List<LessonDefinition> lessons) async {
    var count = 0;
    for (final lesson in lessons) {
      final offlineLesson =
          await _ref.read(offlineLessonV2Provider(lesson.id).future);
      if (offlineLesson != null) {
        count++;
      }
    }
    return count;
  }

  Future<int> _lessonDirectorySize(String lessonId) async {
    final directory = await _offlineStorageService.getLessonDirectory(lessonId);
    if (!await directory.exists()) {
      return 0;
    }

    var totalBytes = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  void _invalidateLessonDownloadProviders(String lessonId) {
    _ref.invalidate(lessonV2DownloadProvider(lessonId));
    _ref.invalidate(offlineLessonV2Provider(lessonId));
    _ref.invalidate(downloadedLessonV2IdsProvider);
    _ref.invalidate(downloadedLessonsV2CountProvider);
    _ref.invalidate(downloadedLessonsV2Provider);
  }

  int _estimatedTotalBytes(int lessonCount) {
    return lessonCount * 3 * 1024 * 1024;
  }

  void _cancelDownloadState(int downloadedBytes, int downloadedLessons) {
    _cancelRequested = false;
    state = state.copyWith(
      isDownloaded: false,
      isLoading: false,
      isError: false,
      isCancelling: false,
      downloadedBytes: downloadedBytes,
      downloadedLessons: downloadedLessons,
      error: null,
    );
    _ref.invalidate(isCourseDownloadedProvider(courseId));
  }
}

final courseV2DownloadProvider = StateNotifierProvider.family<
    CourseV2DownloadNotifier, CourseV2DownloadState, String>((ref, courseId) {
  return CourseV2DownloadNotifier(ref, courseId);
});

final isCourseDownloadedProvider =
    FutureProvider.family<bool, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  final lessonGroups = await Future.wait(
    completeCourse.modules.map(
      (module) => ref.watch(
        lessons_v2.moduleLessonsProvider(module.module.id).future,
      ),
    ),
  );
  final lessonIds = lessonGroups
      .expand((lessons) => lessons)
      .map((lesson) => lesson.id)
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  if (lessonIds.isEmpty) {
    return false;
  }

  for (final lessonId in lessonIds) {
    final offlineLesson =
        await ref.watch(offlineLessonV2Provider(lessonId).future);
    if (offlineLesson == null) {
      return false;
    }
  }

  return true;
});
