import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:milpress/features/lessons_v2/services/lesson_v2_offline_progress_service.dart';
import 'package:milpress/providers/connectivity_provider.dart';
import 'package:milpress/utils/supabase_config.dart';

class LessonV2ProgressSyncService {
  LessonV2ProgressSyncService({
    LessonV2OfflineProgressService? offlineProgressService,
    Connectivity? connectivity,
  })  : _offlineProgressService =
            offlineProgressService ?? LessonV2OfflineProgressService(),
        _connectivity = connectivity ?? Connectivity();

  final LessonV2OfflineProgressService _offlineProgressService;
  final Connectivity _connectivity;

  Future<void> syncPendingProgress() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (isOfflineResult(connectivityResult)) {
        return;
      }

      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final unsynced = await _offlineProgressService.getUnsynced();
      for (final record in unsynced) {
        await SupabaseConfig.client.from('lesson_completion').upsert(
          {
            'user_id': userId,
            'lesson_id': record.lessonId,
            'attempt_count': record.attemptCount,
            'last_attempt_at': record.completedAt.toIso8601String(),
            'completed_at': record.completedAt.toIso8601String(),
          },
          onConflict: 'user_id,lesson_id',
        );
        await _offlineProgressService.markSynced(record.lessonId);
      }
    } catch (e) {
      debugPrint('LessonV2ProgressSyncService: sync skipped: $e');
    }
  }
}
