import 'package:hive/hive.dart';

part 'course_progress_model.g.dart';

@HiveType(typeId: 11)
class CourseProgressModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String userId;
  @HiveField(2)
  String courseId;
  @HiveField(3)
  DateTime? startedAt;
  @HiveField(4)
  DateTime? completedAt;
  @HiveField(5)
  String? currentModuleId;
  @HiveField(6)
  String? currentLessonId;
  @HiveField(7)
  bool isCompleted;
  @HiveField(8)
  DateTime createdAt;
  @HiveField(9)
  DateTime updatedAt;
  @HiveField(10)
  bool needsSync;

  CourseProgressModel({
    required this.id,
    required this.userId,
    required this.courseId,
    this.startedAt,
    this.completedAt,
    this.currentModuleId,
    this.currentLessonId,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
  });

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    return CourseProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      currentModuleId: json['current_module_id'] as String?,
      currentLessonId: json['current_lesson_id'] as String?,
      isCompleted: json['is_completed'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      needsSync: false, // Data from Supabase is always synced
    );
  }
}
