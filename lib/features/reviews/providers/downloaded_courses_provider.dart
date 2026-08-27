import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart'
    as lessons_v2;
import 'package:milpress/features/lessons_v2/providers/lesson_v2_download_provider.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_offline_storage_service.dart';

class DownloadedCourseItem {
  final CompleteCourseModel course;
  final bool isStored;
  final int storedBytes;
  final int availableBytes;
  final int totalLessons;

  const DownloadedCourseItem({
    required this.course,
    required this.isStored,
    required this.storedBytes,
    required this.availableBytes,
    required this.totalLessons,
  });
}

final downloadedCoursesProvider =
    FutureProvider<List<DownloadedCourseItem>>((ref) async {
  final downloadedIds =
      (await ref.watch(downloadedLessonV2IdsProvider.future)).toSet();
  if (downloadedIds.isEmpty) {
    return <DownloadedCourseItem>[];
  }

  final lessonStorageService = LessonV2OfflineStorageService();
  final courseStorageService = ref.watch(courseOfflineStorageServiceProvider);
  final downloadedLessons = await _readDownloadedLessons(ref, downloadedIds);
  final courses = await courseStorageService.listCachedCourses();

  final items = <DownloadedCourseItem>[];
  for (final completeCourse in courses) {
    final moduleIds = completeCourse.modules
        .map((module) => module.module.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    final localLessonIds = downloadedLessons
        .where((lesson) => moduleIds.contains(lesson.moduleId))
        .map((lesson) => lesson.id)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    var lessonIds = localLessonIds;
    if (lessonIds.isEmpty) {
      lessonIds = await _courseLessonIds(ref, completeCourse);
    }

    if (lessonIds.isEmpty) {
      continue;
    }

    final hasDownloadedLesson = lessonIds.any(downloadedIds.contains);
    if (!hasDownloadedLesson) {
      continue;
    }

    final isStored = lessonIds.every(downloadedIds.contains);
    var storedBytes = 0;
    for (final lessonId in lessonIds.where(downloadedIds.contains)) {
      storedBytes += await _lessonDirectorySize(lessonStorageService, lessonId);
    }

    items.add(
      DownloadedCourseItem(
        course: completeCourse,
        isStored: isStored,
        storedBytes: storedBytes,
        availableBytes:
            isStored ? storedBytes : lessonIds.length * 3 * 1024 * 1024,
        totalLessons: lessonIds.length,
      ),
    );
  }

  return items;
});

Future<List<String>> _courseLessonIds(
  Ref ref,
  CompleteCourseModel course,
) async {
  final lessonGroups = await Future.wait(
    course.modules.map(
      (module) => ref.watch(
        lessons_v2.moduleLessonsProvider(module.module.id).future,
      ),
    ),
  );
  return lessonGroups
      .expand((lessons) => lessons)
      .map((lesson) => lesson.id)
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
}

Future<List<LessonDefinition>> _readDownloadedLessons(
  Ref ref,
  Set<String> downloadedIds,
) async {
  final lessons = await Future.wait(
    downloadedIds.map((id) => ref.read(offlineLessonV2Provider(id).future)),
  );
  return lessons.whereType<LessonDefinition>().toList(growable: false);
}

Future<int> _lessonDirectorySize(
  LessonV2OfflineStorageService storageService,
  String lessonId,
) async {
  final directory = await storageService.getLessonDirectory(lessonId);
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
