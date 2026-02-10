import 'package:hive/hive.dart';

part 'course_assessment_model.g.dart';

@HiveType(typeId: 15)
class CourseAssessment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final bool isActive;
  @HiveField(5)
  final DateTime? createdAt;
  @HiveField(6)
  final DateTime? updatedAt;

  CourseAssessment({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseAssessment.fromJson(Map<String, dynamic> json) =>
      CourseAssessment(
        id: json['id'] as String,
        courseId: json['course_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
