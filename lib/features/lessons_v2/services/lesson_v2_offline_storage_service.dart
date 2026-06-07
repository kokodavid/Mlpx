import 'dart:convert';
import 'dart:io';

import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:path_provider/path_provider.dart';

const _offlineLessonsDirectoryName = 'offline_lessons_v2';
const _lessonDataFileName = 'lesson_data.json';
const _lessonKey = 'lesson';
const _stepsKey = 'steps';
const _downloadedAtKey = 'downloaded_at';
const _stepTypeKey = 'step_type';
const _configKey = 'config';

class LessonV2OfflineStorageService {
  String _userId() {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  Future<Directory> getLessonDirectory(String lessonId) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDirectory.path}/$_offlineLessonsDirectoryName/${_userId()}/$lessonId',
    );
  }

  Future<Directory> getOfflineLessonsDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDirectory.path}/$_offlineLessonsDirectoryName/${_userId()}',
    );
  }

  Future<bool> isDownloaded(String lessonId) async {
    final lessonDataFile = await _getLessonDataFile(lessonId);
    return lessonDataFile.exists();
  }

  Future<void> saveLesson(
    LessonDefinition lesson,
    Map<String, String> localAssetPaths,
  ) async {
    final lessonDirectory = await getLessonDirectory(lesson.id);
    if (!await lessonDirectory.exists()) {
      await lessonDirectory.create(recursive: true);
    }

    final data = <String, dynamic>{
      _lessonKey: lesson.toSupabase(),
      _stepsKey: _buildStepRows(lesson, localAssetPaths),
      _downloadedAtKey: DateTime.now().toIso8601String(),
    };

    final lessonDataFile = _lessonDataFile(lessonDirectory);
    await lessonDataFile.writeAsString(jsonEncode(data));
  }

  Future<LessonDefinition?> readLesson(String lessonId) async {
    try {
      final lessonDataFile = await _getLessonDataFile(lessonId);
      if (!await lessonDataFile.exists()) {
        return null;
      }

      final data = jsonDecode(await lessonDataFile.readAsString());
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final lessonRow = data[_lessonKey];
      final stepRows = data[_stepsKey];
      if (lessonRow is! Map || stepRows is! List) {
        return null;
      }

      return LessonDefinition.fromSupabase(
        lessonRow.cast<String, dynamic>(),
        stepRows
            .whereType<Map>()
            .map((row) => row.cast<String, dynamic>())
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    final lessonDirectory = await getLessonDirectory(lessonId);
    if (await lessonDirectory.exists()) {
      await lessonDirectory.delete(recursive: true);
    }
  }

  Future<DateTime?> readDownloadedAt(String lessonId) async {
    try {
      final lessonDataFile = await _getLessonDataFile(lessonId);
      if (!await lessonDataFile.exists()) {
        return null;
      }

      final data = jsonDecode(await lessonDataFile.readAsString());
      if (data is Map<String, dynamic>) {
        final downloadedAt = data[_downloadedAtKey] as String?;
        if (downloadedAt != null) {
          return DateTime.tryParse(downloadedAt)?.toLocal();
        }
      }

      return (await lessonDataFile.lastModified()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> listDownloadedLessonIds() async {
    final offlineLessonsDirectory = await getOfflineLessonsDirectory();
    if (!await offlineLessonsDirectory.exists()) {
      return <String>[];
    }

    final lessonDirectories = await offlineLessonsDirectory.list().toList();
    final ids = <String>[];
    for (final entity in lessonDirectories) {
      if (entity is Directory) {
        final lessonDataFile = _lessonDataFile(entity);
        if (await lessonDataFile.exists()) {
          ids.add(_lastPathSegment(entity.path));
        }
      }
    }
    return ids;
  }

  Future<File> _getLessonDataFile(String lessonId) async {
    final lessonDirectory = await getLessonDirectory(lessonId);
    return _lessonDataFile(lessonDirectory);
  }

  List<Map<String, dynamic>> _buildStepRows(
    LessonDefinition lesson,
    Map<String, String> localAssetPaths,
  ) {
    final stepRows = <Map<String, dynamic>>[];
    for (var index = 0; index < lesson.steps.length; index++) {
      final step = lesson.steps[index];
      stepRows.add(_buildStepRow(lesson.id, step, index, localAssetPaths));
    }
    return stepRows;
  }

  Map<String, dynamic> _buildStepRow(
    String lessonId,
    LessonStepDefinition step,
    int index,
    Map<String, String> localAssetPaths,
  ) {
    return step.toSupabase(lessonId, index).map((key, value) {
      if (key == _stepTypeKey) {
        return MapEntry(key, _stepTypeToStorageValue(step.type));
      }
      if (key == _configKey && value is Map<String, dynamic>) {
        return MapEntry(key, _rewriteLocalAssetPaths(value, localAssetPaths));
      }
      return MapEntry(key, value);
    });
  }

  File _lessonDataFile(Directory lessonDirectory) {
    return File('${lessonDirectory.path}/$_lessonDataFileName');
  }

  dynamic _rewriteLocalAssetPaths(
    dynamic value,
    Map<String, String> localAssetPaths, [
    String? key,
  ]) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (childKey, childValue) => MapEntry(
          childKey,
          _rewriteLocalAssetPaths(childValue, localAssetPaths, childKey),
        ),
      );
    }

    if (value is List) {
      if (key != null && _isAssetUrlListKey(key)) {
        return value
            .map(
              (item) => item is String ? localAssetPaths[item] ?? item : item,
            )
            .toList(growable: false);
      }

      return value
          .map((item) => _rewriteLocalAssetPaths(item, localAssetPaths, key))
          .toList(growable: false);
    }

    if (key != null && _isAssetUrlKey(key) && value is String) {
      return localAssetPaths[value] ?? value;
    }

    return value;
  }

  String _lastPathSegment(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  bool _isAssetUrlKey(String key) {
    return key.endsWith('_url') || key == 'url';
  }

  bool _isAssetUrlListKey(String key) {
    return key.endsWith('_urls') || key == 'urls';
  }

  String _stepTypeToStorageValue(LessonStepType type) {
    switch (type) {
      case LessonStepType.soundDiscrimination:
        return 'sound_discrimination';
      case LessonStepType.soundItemMatching:
        return 'sound_item_matching';
      case LessonStepType.guidedReading:
        return 'guided_reading';
      case LessonStepType.practiceGame:
        return 'practice_game';
      case LessonStepType.soundPresenceCheck:
        return 'sound_presence_check';
      case LessonStepType.missingLetters:
        return 'missing_letters';
      case LessonStepType.matchingWords:
        return 'matching_words';
      case LessonStepType.wordReading:
        return 'word_reading';
      case LessonStepType.sentenceReading:
        return 'sentence_reading';
      case LessonStepType.miniStoryCard:
        return 'mini_story_card';
      case LessonStepType.introduction:
      case LessonStepType.demonstration:
      case LessonStepType.practice:
      case LessonStepType.assessment:
      case LessonStepType.blending:
        return type.name;
    }
  }
}