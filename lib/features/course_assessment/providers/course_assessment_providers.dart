import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assessment_v2_composites.dart';
import '../models/assessment_v2_progress_model.dart';
import '../repositories/course_assessment_repository.dart';

// Repository singleton
final courseAssessmentRepositoryProvider =
    Provider<CourseAssessmentRepository>((ref) {
  return CourseAssessmentRepository();
});

/// Fetch the full assessment tree by course ID
/// Returns AssessmentWithLevels (assessment + levels + sublevels with questions)
final courseAssessmentProvider =
    FutureProvider.family<AssessmentWithLevels?, String>(
        (ref, courseId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchAssessmentByCourseId(courseId);
});

/// Fetch the full assessment tree by assessment ID directly
/// Used when navigating from a module that has an assessment_id
final assessmentByIdProvider =
    FutureProvider.family<AssessmentWithLevels?, String>(
        (ref, assessmentId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchAssessmentById(assessmentId);
});

/// Fetch user progress for all sublevels in an assessment
final assessmentProgressProvider =
    FutureProvider.family<List<AssessmentV2Progress>, String>(
        (ref, assessmentId) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  return repository.fetchProgress(assessmentId);
});

/// Save progress for a sublevel and return the updated record
final saveAssessmentProgressProvider =
    FutureProvider.family<AssessmentV2Progress?, AssessmentV2Progress>(
        (ref, progress) async {
  final repository = ref.watch(courseAssessmentRepositoryProvider);
  final result = await repository.saveProgress(progress);
  if (result != null) {
    // Invalidate progress so UI reflects the update
    ref.invalidate(assessmentProgressProvider(progress.assessmentId));
  }
  return result;
});
