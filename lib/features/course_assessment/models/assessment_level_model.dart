import 'package:hive/hive.dart';

part 'assessment_level_model.g.dart';

@HiveType(typeId: 16)
class AssessmentLevel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String assessmentId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final int displayOrder;
  @HiveField(5)
  final DateTime? createdAt;
  @HiveField(6)
  final DateTime? updatedAt;

  AssessmentLevel({
    required this.id,
    required this.assessmentId,
    required this.title,
    this.description,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory AssessmentLevel.fromJson(Map<String, dynamic> json) =>
      AssessmentLevel(
        id: json['id'] as String,
        assessmentId: json['assessment_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        displayOrder: json['display_order'] as int,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessment_id': assessmentId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
