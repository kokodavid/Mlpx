class LessonAttemptRequest {
  final String lessonId;
  final String? userId;
  final bool markCompleted;

  const LessonAttemptRequest({
    required this.lessonId,
    this.userId,
    this.markCompleted = false,
  });
}
