import 'package:hive/hive.dart';
import 'course_model.dart';
import 'module_model.dart';
import 'lesson_model.dart';

part 'complete_course_model.g.dart';

@HiveType(typeId: 1)
class CompleteCourseModel {
  @HiveField(0)
  final CourseModel course;

  @HiveField(1)
  final List<ModuleWithLessons> modules;

  @HiveField(2)
  final DateTime lastUpdated;

  CompleteCourseModel({
    required this.course,
    required this.modules,
    required this.lastUpdated,
  });

  factory CompleteCourseModel.fromJson(Map<String, dynamic> json) {
    return CompleteCourseModel(
      course: CourseModel.fromJson(json['course']),
      modules: (json['modules'] as List)
          .map((module) => ModuleWithLessons.fromJson(module))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'course': course.toJson(),
        'modules': modules.map((module) => module.toJson()).toList(),
        'last_updated': lastUpdated.toIso8601String(),
      };
}

@HiveType(typeId: 2)
class ModuleWithLessons {
  @HiveField(0)
  final ModuleModel module;

  @HiveField(1)
  final List<LessonModel> lessons;

  ModuleWithLessons({
    required this.module,
    required this.lessons,
  });

  factory ModuleWithLessons.fromJson(Map<String, dynamic> json) {
    return ModuleWithLessons(
      module: ModuleModel.fromJson(json['module']),
      lessons: (json['lessons'] as List)
          .map((lesson) => LessonModel.fromJson(lesson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'module': module.toJson(),
        'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      };
} 