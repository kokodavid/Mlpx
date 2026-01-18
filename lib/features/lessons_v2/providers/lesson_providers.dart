import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_models.dart';
import '../repositories/lesson_repository.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository();
});

final lessonDefinitionProvider =
    FutureProvider.family<LessonDefinition?, String>((ref, lessonId) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.fetchLessonById(lessonId);
});

final moduleLessonsProvider =
    FutureProvider.family<List<LessonDefinition>, String>((ref, moduleId) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.fetchLessonsForModule(moduleId);
});
