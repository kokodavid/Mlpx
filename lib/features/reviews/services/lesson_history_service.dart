import 'package:hive/hive.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';

class LessonHistoryService {
  Future<List<LessonProgressModel>> getCompletedLessons(String userId) async {
    final box = await Hive.openBox<LessonProgressModel>('lesson_progress');
    final allLessons = box.values.where((lp) => lp.userId == userId && lp.status == 'completed').toList();
    allLessons.sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime(1970)) ?? 0);
    return allLessons;
  }
} 