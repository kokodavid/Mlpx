import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/repositories/lesson_repository.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_asset_download_service.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_offline_storage_service.dart';

const _assetDirectoryName = 'assets';
const _assetFilePrefix = 'asset';
const _downloadErrorPrefix = 'LessonV2DownloadRepository: failed to download';
const _lessonNotFoundMessage = 'Lesson not found';

class LessonV2DownloadRepository {
  LessonV2DownloadRepository({
    required LessonRepository lessonRepository,
    LessonV2AssetDownloadService? assetDownloadService,
    LessonV2OfflineStorageService? offlineStorageService,
  })  : _lessonRepository = lessonRepository,
        _assetDownloadService =
            assetDownloadService ?? LessonV2AssetDownloadService(),
        _offlineStorageService =
            offlineStorageService ?? LessonV2OfflineStorageService();

  final LessonRepository _lessonRepository;
  final LessonV2AssetDownloadService _assetDownloadService;
  final LessonV2OfflineStorageService _offlineStorageService;

  Future<void> downloadLesson(LessonDefinition lesson) async {
    final lessonId = lesson.id;
    final lessonDirectory =
        await _offlineStorageService.getLessonDirectory(lessonId);

    try {
      if (await lessonDirectory.exists()) {
        await lessonDirectory.delete(recursive: true);
      }
      await lessonDirectory.create(recursive: true);

      final lessonToSave = await _resolveLessonToSave(lesson);
      final localAssetPaths = await _downloadAssets(
        lessonToSave,
        lessonDirectory,
      );

      await _offlineStorageService.saveLesson(lessonToSave, localAssetPaths);
    } catch (_) {
      if (await lessonDirectory.exists()) {
        await lessonDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<LessonDefinition?> readLesson(String lessonId) {
    return _offlineStorageService.readLesson(lessonId);
  }

  Future<bool> isDownloaded(String lessonId) {
    return _offlineStorageService.isDownloaded(lessonId);
  }

  Future<void> removeDownload(String lessonId) {
    return _offlineStorageService.deleteLesson(lessonId);
  }

  Future<DateTime?> readDownloadedAt(String lessonId) {
    return _offlineStorageService.readDownloadedAt(lessonId);
  }

  Future<List<String>> listDownloadedLessonIds() {
    return _offlineStorageService.listDownloadedLessonIds();
  }

  Future<LessonDefinition> _resolveLessonToSave(
    LessonDefinition lesson,
  ) async {
    final fullLesson = await _lessonRepository.fetchLessonById(lesson.id);
    final lessonToSave = fullLesson ?? (lesson.steps.isNotEmpty ? lesson : null);
    if (lessonToSave == null) {
      throw Exception(_lessonNotFoundMessage);
    }
    return lessonToSave;
  }

  Future<Map<String, String>> _downloadAssets(
    LessonDefinition lesson,
    Directory lessonDirectory,
  ) async {
    final assetUrls = _collectAssetUrls(lesson).toList();
    final assetDirectory = Directory(
      '${lessonDirectory.path}/$_assetDirectoryName',
    );
    final localAssetPaths = <String, String>{};

    for (var index = 0; index < assetUrls.length; index++) {
      final url = assetUrls[index];
      try {
        localAssetPaths[url] = await _assetDownloadService.downloadUrl(
          url: url,
          directory: assetDirectory,
          fileName: _fileNameForUrl(url, index),
        );
      } catch (e) {
        debugPrint('$_downloadErrorPrefix $url: $e');
      }
    }
    return localAssetPaths;
  }

  Set<String> _collectAssetUrls(LessonDefinition lesson) {
    final urls = <String>{};
    for (final step in lesson.steps) {
      _collectAssetUrlsFromValue(step.config, urls);
    }
    return urls;
  }

  void _collectAssetUrlsFromValue(
    dynamic value,
    Set<String> urls, [
    String? key,
  ]) {
    if (value is Map<String, dynamic>) {
      value.forEach((childKey, childValue) {
        _collectAssetUrlsFromValue(childValue, urls, childKey);
      });
      return;
    }

    if (value is List) {
      for (final item in value) {
        if (key != null &&
            _isAssetUrlListKey(key) &&
            item is String &&
            item.trim().isNotEmpty &&
            _isRemoteUrl(item)) {
          urls.add(item);
        } else {
          _collectAssetUrlsFromValue(item, urls, key);
        }
      }
      return;
    }

    if (key != null &&
        _isAssetUrlKey(key) &&
        value is String &&
        value.trim().isNotEmpty &&
        _isRemoteUrl(value)) {
      urls.add(value);
    }
  }

  bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isAssetUrlKey(String key) {
    return key.endsWith('_url') || key == 'url';
  }

  bool _isAssetUrlListKey(String key) {
    return key.endsWith('_urls') || key == 'urls';
  }

  String _fileNameForUrl(String url, int index) {
    final uri = Uri.tryParse(url);
    final pathSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '${_assetFilePrefix}_$index';
    final extensionIndex = pathSegment.lastIndexOf('.');
    final extension =
        extensionIndex == -1 ? '' : pathSegment.substring(extensionIndex);
    return '${_assetFilePrefix}_${index.toString().padLeft(3, '0')}$extension';
  }
}
