import 'dart:convert';
import 'dart:io';

import 'package:milpress/utils/supabase_config.dart';
import 'package:path_provider/path_provider.dart';

const _offlineProgressDirectoryName = 'offline_progress_v2';
const _progressFileName = 'progress.json';

class LessonV2OfflineProgressRecord {
  final String lessonId;
  final DateTime completedAt;
  final int attemptCount;
  final bool synced;

  const LessonV2OfflineProgressRecord({
    required this.lessonId,
    required this.completedAt,
    required this.attemptCount,
    required this.synced,
  });

  factory LessonV2OfflineProgressRecord.fromJson(Map<String, dynamic> json) {
    return LessonV2OfflineProgressRecord(
      lessonId: json['lessonId'] as String? ?? '',
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
              DateTime.now(),
      attemptCount: json['attemptCount'] as int? ?? 0,
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'completedAt': completedAt.toIso8601String(),
      'attemptCount': attemptCount,
      'synced': synced,
    };
  }

  LessonV2OfflineProgressRecord copyWith({
    DateTime? completedAt,
    int? attemptCount,
    bool? synced,
  }) {
    return LessonV2OfflineProgressRecord(
      lessonId: lessonId,
      completedAt: completedAt ?? this.completedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      synced: synced ?? this.synced,
    );
  }
}

class LessonV2OfflineProgressService {
  String _userId() {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  Future<void> saveProgress(String lessonId) async {
    if (lessonId.isEmpty) return;

    final records = await _readRecords();
    final existing = records[lessonId];
    records[lessonId] = LessonV2OfflineProgressRecord(
      lessonId: lessonId,
      completedAt: existing?.completedAt ?? DateTime.now(),
      attemptCount: (existing?.attemptCount ?? 0) + 1,
      synced: false,
    );
    await _writeRecords(records);
  }

  Future<bool> isCompleted(String lessonId) async {
    final records = await _readRecords();
    return records.containsKey(lessonId);
  }

  Future<List<LessonV2OfflineProgressRecord>> getUnsynced() async {
    final records = await _readRecords();
    return records.values
        .where((record) => !record.synced)
        .toList(growable: false);
  }

  Future<void> markSynced(String lessonId) async {
    final records = await _readRecords();
    final existing = records[lessonId];
    if (existing == null) return;

    records[lessonId] = existing.copyWith(synced: true);
    await _writeRecords(records);
  }

  Future<List<String>> listCompletedLessonIds() async {
    final records = await _readRecords();
    return records.keys.toList(growable: false);
  }

  Future<LessonV2OfflineProgressRecord?> readProgress(String lessonId) async {
    final records = await _readRecords();
    return records[lessonId];
  }

  Future<File> _progressFile() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${appDirectory.path}/$_offlineProgressDirectoryName/${_userId()}',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/$_progressFileName');
  }

  Future<Map<String, LessonV2OfflineProgressRecord>> _readRecords() async {
    try {
      final file = await _progressFile();
      if (!await file.exists()) {
        return <String, LessonV2OfflineProgressRecord>{};
      }

      final data = jsonDecode(await file.readAsString());
      if (data is! List) {
        return <String, LessonV2OfflineProgressRecord>{};
      }

      return {
        for (final item in data.whereType<Map>())
          LessonV2OfflineProgressRecord.fromJson(
            item.cast<String, dynamic>(),
          ).lessonId: LessonV2OfflineProgressRecord.fromJson(
            item.cast<String, dynamic>(),
          ),
      }..removeWhere((lessonId, _) => lessonId.isEmpty);
    } catch (_) {
      return <String, LessonV2OfflineProgressRecord>{};
    }
  }

  Future<void> _writeRecords(
    Map<String, LessonV2OfflineProgressRecord> records,
  ) async {
    final file = await _progressFile();
    final values = records.values
        .map((record) => record.toJson())
        .toList(growable: false);
    await file.writeAsString(jsonEncode(values));
  }
}
