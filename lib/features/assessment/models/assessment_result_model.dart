import 'package:hive/hive.dart';

part 'assessment_result_model.g.dart';

@HiveType(typeId: 14)
class AssessmentResultModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime completedAt;

  @HiveField(2)
  Map<String, int> stageScores;

  @HiveField(3)
  Map<String, int> totalQuestionsPerStage;

  @HiveField(4)
  double overallScore;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  AssessmentResultModel({
    required this.id,
    required this.completedAt,
    required this.stageScores,
    required this.totalQuestionsPerStage,
    required this.overallScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) {
    return AssessmentResultModel(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      stageScores: Map<String, int>.from(json['stage_scores'] as Map),
      totalQuestionsPerStage: Map<String, int>.from(json['total_questions_per_stage'] as Map),
      overallScore: (json['overall_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completed_at': completedAt.toIso8601String(),
      'stage_scores': stageScores,
      'total_questions_per_stage': totalQuestionsPerStage,
      'overall_score': overallScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 