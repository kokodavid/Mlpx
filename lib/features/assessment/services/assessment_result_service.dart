import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/assessment_result_model.dart';

class AssessmentResultService {
  static const String boxName = 'assessment_results';
  static const String latestResultKey = 'latest_assessment';

  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    final box = await Hive.openBox<AssessmentResultModel>(boxName);
    await box.put(latestResultKey, result);
    print('Assessment result saved: ${result.id}');
  }

  Future<AssessmentResultModel?> getLatestAssessmentResult() async {
    final box = await Hive.openBox<AssessmentResultModel>(boxName);
    return box.get(latestResultKey);
  }

  Future<bool> hasCompletedAssessment() async {
    final result = await getLatestAssessmentResult();
    return result != null;
  }

  Future<void> clearAssessmentResult() async {
    final box = await Hive.openBox<AssessmentResultModel>(boxName);
    await box.delete(latestResultKey);
    print('Assessment result cleared');
  }

  AssessmentResultModel createAssessmentResult({
    required Map<String, int> stageScores,
    required Map<String, int> totalQuestionsPerStage,
  }) {
    final now = DateTime.now();
    final uuid = Uuid().v4();
    
    // Calculate overall score
    int totalScore = 0;
    int totalPossible = 0;
    stageScores.forEach((stage, score) {
      totalScore += score;
      totalPossible += totalQuestionsPerStage[stage] ?? 0;
    });
    final overallScore = totalPossible > 0 ? (totalScore / totalPossible) * 100.0 : 0.0;

    return AssessmentResultModel(
      id: uuid,
      completedAt: now,
      stageScores: stageScores,
      totalQuestionsPerStage: totalQuestionsPerStage,
      overallScore: overallScore,
      createdAt: now,
      updatedAt: now,
    );
  }
} 