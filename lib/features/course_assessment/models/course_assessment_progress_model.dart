import 'package:hive/hive.dart';

part 'course_assessment_progress_model.g.dart';

@HiveType(typeId: 18)
class CourseAssessmentProgress {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String sublevelId;
  @HiveField(3)
  final String assessmentId;
  @HiveField(4)
  final int? score;
  @HiveField(7)
  final int attempts;
  @HiveField(8)
  final Map<String, dynamic>? answers;
  @HiveField(9)
  final DateTime? startedAt;
  @HiveField(10)
  final DateTime? completedAt;
  @HiveField(11)
  final DateTime? createdAt;
  @HiveField(12)
  final DateTime? updatedAt;

  CourseAssessmentProgress({
    required this.id,
    required this.userId,
    required this.sublevelId,
    required this.assessmentId,
    this.score,
    this.attempts = 0,
    this.answers,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseAssessmentProgress.fromJson(Map<String, dynamic> json) =>
      CourseAssessmentProgress(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        sublevelId: json['sublevel_id'] as String,
        assessmentId: json['assessment_id'] as String,
        score: json['score'] as int?,
        attempts: json['attempts'] as int? ?? 0,
        answers: json['answers'] as Map<String, dynamic>?,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'])
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'sublevel_id': sublevelId,
        'assessment_id': assessmentId,
        'score': score,
        'attempts': attempts,
        'answers': answers,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
