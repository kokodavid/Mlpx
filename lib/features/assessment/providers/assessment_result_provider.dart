import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assessment_result_service.dart';
import '../models/assessment_result_model.dart';

// Service provider
final assessmentResultServiceProvider = Provider<AssessmentResultService>((ref) {
  return AssessmentResultService();
});

// Provider to get the latest assessment result
final latestAssessmentResultProvider = FutureProvider<AssessmentResultModel?>((ref) async {
  final service = ref.read(assessmentResultServiceProvider);
  return await service.getLatestAssessmentResult();
});

// Provider to check if user has completed assessment
final hasCompletedAssessmentProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(assessmentResultServiceProvider);
  return await service.hasCompletedAssessment();
});

// Provider to save assessment result
final saveAssessmentResultProvider = FutureProvider.family<void, AssessmentResultModel>((ref, result) async {
  final service = ref.read(assessmentResultServiceProvider);
  await service.saveAssessmentResult(result);
}); 