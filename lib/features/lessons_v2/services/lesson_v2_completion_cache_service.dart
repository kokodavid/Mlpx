import 'dart:convert';
import 'dart:io';

import 'package:milpress/utils/supabase_config.dart';
import 'package:path_provider/path_provider.dart';

const _completionCacheDirectoryName = 'lesson_completion_cache_v2';
const _completionCacheFileName = 'completed_lesson_ids.json';
const _lessonIdsKey = 'lesson_ids';
const _updatedAtKey = 'updated_at';

class LessonV2CompletionCacheService {
  String _userId() {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  Future<void> saveCompletedLessonIds(
    String moduleId,
    Set<String> lessonIds,
  ) async {
    if (moduleId.isEmpty) return;

    final file = await _completionCacheFile(moduleId);
    final data = <String, dynamic>{
      _lessonIdsKey: lessonIds.toList(growable: false),
      _updatedAtKey: DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  Future<Set<String>> readCompletedLessonIds(String moduleId) async {
    if (moduleId.isEmpty) return <String>{};

    try {
      final file = await _completionCacheFile(moduleId);
      if (!await file.exists()) {
        return <String>{};
      }

      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) {
        return <String>{};
      }

      final lessonIds = data[_lessonIdsKey];
      if (lessonIds is! List) {
        return <String>{};
      }

      return lessonIds.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<File> _completionCacheFile(String moduleId) async {
    final directory = await _moduleCacheDirectory(moduleId);
    return File('${directory.path}/$_completionCacheFileName');
  }

  Future<Directory> _moduleCacheDirectory(String moduleId) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${appDirectory.path}/$_completionCacheDirectoryName/${_userId()}/$moduleId',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
