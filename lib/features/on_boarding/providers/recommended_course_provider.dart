import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/course_models/course_model.dart';

class RecommendedCourseNotifier extends StateNotifier<CourseModel?> {
  RecommendedCourseNotifier() : super(null);

  void setRecommendedCourse(CourseModel course) {
    state = course;
  }

  void clearRecommendedCourse() {
    state = null;
  }

  bool get hasRecommendedCourse => state != null;
}

final recommendedCourseProvider = StateNotifierProvider<RecommendedCourseNotifier, CourseModel?>((ref) {
  return RecommendedCourseNotifier();
}); 