import 'package:hive/hive.dart';

part 'module_model.g.dart';

@HiveType(typeId: 4)
class ModuleModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  final int position;
  @HiveField(3)
  final DateTime? createdAt;
  @HiveField(4)
  final DateTime? updatedAt;
  @HiveField(5)
  final int durationInMinutes;
  @HiveField(6)
  final bool locked;
  @HiveField(7)
  final String lockMessage;
  @HiveField(8)
  final String description;

  ModuleModel({
    required this.id,
    required this.courseId,
    required this.position,
    this.createdAt,
    this.updatedAt,
    required this.durationInMinutes,
    required this.locked,
    required this.lockMessage,
    required this.description,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String,
        position: json['position'] as int,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        durationInMinutes: json['duration_minutes'] as int,
        locked: json['locked'] as bool,
        lockMessage: json['lock_message'] as String,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'position': position,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'duration_minutes': durationInMinutes,
        'locked': locked,
        'lock_message': lockMessage,
        'description': description,
      };
}
