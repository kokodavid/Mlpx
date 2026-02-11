import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assessment_v2_composites.dart';
import '../models/assessment_v2_progress_model.dart';
import '../repositories/course_assessment_repository.dart';

final courseAssessmentRepositoryProvider =
    Provider<CourseAssessmentRepository>((ref) {
  return CourseAssessmentRepository();
});

final courseAssessmentProvider =
    FutureProvider.family<AssessmentWithLevels?, String>(
        (ref, courseId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchAssessmentByCourseId(courseId);
});

final assessmentByIdProvider =
    FutureProvider.family<AssessmentWithLevels?, String>(
        (ref, assessmentId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchAssessmentById(assessmentId);
});

final assessmentProgressProvider =
    FutureProvider.family<List<AssessmentV2Progress>, String>(
        (ref, assessmentId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchProgress(assessmentId);
});

final saveAssessmentProgressProvider =
    FutureProvider.family<AssessmentV2Progress?, AssessmentV2Progress>(
        (ref, progress) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  final result = await repository.saveProgress(progress);
  if (result != null) {
    ref.invalidate(assessmentProgressProvider(progress.assessmentId));
  }
  return result;
});
