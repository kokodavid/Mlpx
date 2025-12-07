import 'package:hive/hive.dart';

part 'lesson_progress_model.g.dart';

@HiveType(typeId: 10)
class LessonProgressModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String userId;
  @HiveField(2)
  String lessonId;
  @HiveField(3)
  String courseProgressId;
  @HiveField(4)
  String status;
  @HiveField(5)
  DateTime? startedAt;
  @HiveField(6)
  DateTime? completedAt;
  @HiveField(7)
  int? videoProgress;
  @HiveField(8)
  int? quizScore;
  @HiveField(9)
  DateTime? quizAttemptedAt;
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  DateTime updatedAt;
  @HiveField(12)
  bool needsSync;
  @HiveField(13)
  int? quizTotalQuestions;
  @HiveField(14)
  String? lessonTitle;

  LessonProgressModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.courseProgressId,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.videoProgress,
    this.quizScore,
    this.quizAttemptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
    this.quizTotalQuestions,
    this.lessonTitle,
  });

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) {
    return LessonProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      courseProgressId: json['course_progress_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      videoProgress: json['video_progress'] as int?,
      quizScore: json['quiz_score'] as int?,
      quizAttemptedAt: json['quiz_attempted_at'] != null ? DateTime.parse(json['quiz_attempted_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      needsSync: false, // Data from Supabase is always synced
      quizTotalQuestions: json['quiz_total_questions'] as int?,
      lessonTitle: json['lesson_title'] as String?,
    );
  }

  LessonProgressModel copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? courseProgressId,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? videoProgress,
    int? quizScore,
    DateTime? quizAttemptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
    int? quizTotalQuestions,
    String? lessonTitle,
  }) {
    return LessonProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      courseProgressId: courseProgressId ?? this.courseProgressId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      videoProgress: videoProgress ?? this.videoProgress,
      quizScore: quizScore ?? this.quizScore,
      quizAttemptedAt: quizAttemptedAt ?? this.quizAttemptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      quizTotalQuestions: quizTotalQuestions ?? this.quizTotalQuestions,
      lessonTitle: lessonTitle ?? this.lessonTitle,
    );
  }
}
