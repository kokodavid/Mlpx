import 'package:hive/hive.dart';

part 'on_boarding_quiz_model.g.dart';

@HiveType(typeId: 7)
class OnboardingQuizModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String stage;
  @HiveField(2)
  String questionType;
  @HiveField(3)
  String questionContent;
  @HiveField(4)
  String? soundFileUrl;
  @HiveField(5)
  String correctAnswer;
  @HiveField(6)
  List<String> options;
  @HiveField(7)
  int? difficultyLevel;
  @HiveField(8)
  DateTime? createdAt;
  @HiveField(9)
  DateTime? updatedAt;

  OnboardingQuizModel({
    required this.id,
    required this.stage,
    required this.questionType,
    required this.questionContent,
    this.soundFileUrl,
    required this.correctAnswer,
    required this.options,
    this.difficultyLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory OnboardingQuizModel.fromJson(Map<String, dynamic> json) {
    return OnboardingQuizModel(
      id: json['id'] as String,
      stage: json['stage'] as String,
      questionType: json['question_type'] as String,
      questionContent: json['question_content'] as String,
      soundFileUrl: json['sound_file_url'] as String?,
      correctAnswer: json['correct_answer'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
      difficultyLevel: json['difficulty_level'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
}
