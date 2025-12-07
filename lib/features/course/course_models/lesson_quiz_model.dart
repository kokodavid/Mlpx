import 'package:hive/hive.dart';

part 'lesson_quiz_model.g.dart';

@HiveType(typeId: 6)
class LessonQuizModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String lessonId;
  @HiveField(2)
  final String stage;
  @HiveField(3)
  final String questionType;
  @HiveField(4)
  final String questionContent;
  @HiveField(5)
  final String? soundFileUrl;
  @HiveField(6)
  final String correctAnswer;
  @HiveField(7)
  final List<String> options;
  @HiveField(8)
  final int difficultyLevel;
  @HiveField(9)
  final DateTime? createdAt;
  @HiveField(10)
  final DateTime? updatedAt;

  LessonQuizModel({
    required this.id,
    required this.lessonId,
    required this.stage,
    required this.questionType,
    required this.questionContent,
    this.soundFileUrl,
    required this.correctAnswer,
    required this.options,
    required this.difficultyLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonQuizModel.fromJson(Map<String, dynamic> json) =>
      LessonQuizModel(
        id: json['id'] as String,
        lessonId: json['lesson_id'] as String,
        stage: json['stage'] as String,
        questionType: json['question_type'] as String,
        questionContent: json['question_content'] as String,
        soundFileUrl: json['sound_file_url'] as String?,
        correctAnswer: json['correct_answer'] as String,
        options:
            (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
        difficultyLevel: json['difficulty_level'] as int,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'stage': stage,
        'question_type': questionType,
        'question_content': questionContent,
        'sound_file_url': soundFileUrl,
        'correct_answer': correctAnswer,
        'options': options,
        'difficulty_level': difficultyLevel,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
