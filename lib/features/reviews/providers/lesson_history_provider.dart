import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/reviews/services/lesson_history_service.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:milpress/utils/supabase_config.dart';

final lessonHistoryServiceProvider = Provider((ref) => LessonHistoryService());

final lessonHistoryProvider = FutureProvider<List<LessonProgressModel>>((ref) async {
  final authUser = ref.watch(authProvider).value;
  final user = authUser ?? SupabaseConfig.currentUser;
  final userId = user?.id;
  if (userId == null) return [];
  final service = ref.watch(lessonHistoryServiceProvider);
  return service.getCompletedLessons(userId);
});

final unsyncedLessonsProvider = FutureProvider<List<LessonProgressModel>>((ref) async {
  return [];
}); 
