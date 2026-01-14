import 'package:hive/hive.dart';

part 'bookmark_model.g.dart';

@HiveType(typeId: 13)
class BookmarkModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String lessonId;

  @HiveField(3)
  final String courseId;

  @HiveField(4)
  final String moduleId;

  @HiveField(5)
  final String lessonTitle;

  @HiveField(6)
  final String courseTitle;

  @HiveField(7)
  final String moduleTitle;

  @HiveField(8)
  final DateTime bookmarkedAt;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool needsSync;

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.courseId,
    required this.moduleId,
    required this.lessonTitle,
    required this.courseTitle,
    required this.moduleTitle,
    required this.bookmarkedAt,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = false,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      courseId: json['course_id'] as String,
      moduleId: json['module_id'] as String,
      lessonTitle: json['lesson_title'] as String,
      courseTitle: json['course_title'] as String,
      moduleTitle: json['module_title'] as String,
      bookmarkedAt: DateTime.parse(json['bookmarked_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'course_id': courseId,
      'module_id': moduleId,
      'lesson_title': lessonTitle,
      'course_title': courseTitle,
      'module_title': moduleTitle,
      'bookmarked_at': bookmarkedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BookmarkModel copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? courseId,
    String? moduleId,
    String? lessonTitle,
    String? courseTitle,
    String? moduleTitle,
    DateTime? bookmarkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      courseTitle: courseTitle ?? this.courseTitle,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
