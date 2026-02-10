import 'package:hive/hive.dart';

part 'assessment_sublevel_model.g.dart';

@HiveType(typeId: 17)
class AssessmentSublevel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String levelId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final int displayOrder;
  @HiveField(5)
  final List<dynamic> questions;
  @HiveField(6)
  final int passingScore;
  @HiveField(7)
  final DateTime? createdAt;
  @HiveField(8)
  final DateTime? updatedAt;

  AssessmentSublevel({
    required this.id,
    required this.levelId,
    required this.title,
    this.description,
    required this.displayOrder,
    required this.questions,
    this.passingScore = 70,
    this.createdAt,
    this.updatedAt,
  });

  factory AssessmentSublevel.fromJson(Map<String, dynamic> json) =>
      AssessmentSublevel(
        id: json['id'] as String,
        levelId: json['level_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        displayOrder: json['display_order'] as int,
        questions: json['questions'] as List<dynamic>? ?? [],
        passingScore: json['passing_score'] as int? ?? 70,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'level_id': levelId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'questions': questions,
        'passing_score': passingScore,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
