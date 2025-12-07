import 'package:hive/hive.dart';

part 'module_progress_model.g.dart';

@HiveType(typeId: 12)
class ModuleProgressModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String userId;
  @HiveField(2)
  String moduleId;
  @HiveField(3)
  String courseProgressId;
  @HiveField(4)
  String status;
  @HiveField(5)
  DateTime? startedAt;
  @HiveField(6)
  DateTime? completedAt;
  @HiveField(7)
  double? averageScore;
  @HiveField(8)
  int totalLessons;
  @HiveField(9)
  int completedLessons;
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  DateTime updatedAt;
  @HiveField(12)
  bool needsSync;

  ModuleProgressModel({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.courseProgressId,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.averageScore,
    required this.totalLessons,
    required this.completedLessons,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
  });

  factory ModuleProgressModel.fromJson(Map<String, dynamic> json) {
    return ModuleProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      courseProgressId: json['course_progress_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      totalLessons: json['total_lessons'] as int? ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      needsSync: false, // Data from Supabase is always synced
    );
  }

  ModuleProgressModel copyWith({
    String? id,
    String? userId,
    String? moduleId,
    String? courseProgressId,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    double? averageScore,
    int? totalLessons,
    int? completedLessons,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return ModuleProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      courseProgressId: courseProgressId ?? this.courseProgressId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      averageScore: averageScore ?? this.averageScore,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }
} 