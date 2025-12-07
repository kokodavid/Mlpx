import 'package:hive/hive.dart';
import 'lesson_quiz_model.dart';

part 'lesson_model.g.dart';

@HiveType(typeId: 5)
class LessonModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String moduleId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String content;
  @HiveField(4)
  final int position;
  @HiveField(5)
  final String? videoUrl;
  @HiveField(6)
  final String? audioUrl;
  @HiveField(7)
  final DateTime? createdAt;
  @HiveField(8)
  final DateTime? updatedAt;
  @HiveField(9)
  final int durationMinutes;
  @HiveField(10)
  final List<LessonQuizModel> quizzes;
  @HiveField(11)
  final String? thumbnailUrl;
  @HiveField(12)
  final String? category;
  @HiveField(13)
  final String? level;
  @HiveField(14)
  final String? description;

  LessonModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    required this.position,
    this.videoUrl,
    this.audioUrl,
    this.createdAt,
    this.updatedAt,
    required this.durationMinutes,
    this.quizzes = const [],
    this.thumbnailUrl,
    this.category,
    this.level,
    this.description,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] as String,
        moduleId: json['module_id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        position: json['position'] as int,
        videoUrl: json['video_url'] as String?,
        audioUrl: json['audio_url'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        durationMinutes: json['duration_minutes'] as int,
        quizzes: (json['quizzes'] as List<dynamic>?)
                ?.map(
                    (q) => LessonQuizModel.fromJson(q as Map<String, dynamic>))
                .toList() ??
            [],
        thumbnailUrl: json['thumbnail_url'] as String?,
        category: json['category'] as String?,
        level: json['level'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        'title': title,
        'content': content,
        'position': position,
        'video_url': videoUrl,
        'audio_url': audioUrl,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'quizzes': quizzes.map((q) => q.toJson()).toList(),
        'thumbnail_url': thumbnailUrl,
        'category': category,
        'level': level,
        'description': description,
      };

  // Helper method to format duration for display
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}m';
    }
  }

  // Helper method to get display category
  String get displayCategory {
    return category ?? 'General';
  }

  // Helper method to get display level
  String get displayLevel {
    return level ?? 'Beginner';
  }
}
