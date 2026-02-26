class LessonCompletionModel {
  final String userId;
  final String lessonId;
  final DateTime? completedAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lessonTitle;
  final String? moduleId;

  const LessonCompletionModel({
    required this.userId,
    required this.lessonId,
    this.completedAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lessonTitle,
    this.moduleId,
  });

  factory LessonCompletionModel.fromJson(Map<String, dynamic> json) {
    final lessonData = json['new_lessons'] as Map<String, dynamic>?;
    return LessonCompletionModel(
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      attemptCount: json['attempt_count'] as int? ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'] as String)
          : null,
      lessonTitle: lessonData?['title'] as String?,
      moduleId: lessonData?['module_id'] as String?,
    );
  }
}
