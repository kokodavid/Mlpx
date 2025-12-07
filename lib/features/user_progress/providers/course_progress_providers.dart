import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/course_progress_service.dart';
import '../models/course_progress_model.dart';

// Service provider
final courseProgressServiceProvider = Provider<CourseProgressService>((ref) {
  final supabase = Supabase.instance.client;
  return CourseProgressService(supabase);
});

// Provider to get or create course progress for a user and course
final getOrCreateCourseProgressProvider = FutureProvider.family<String, String>((ref, courseId) async {
  final service = ref.read(courseProgressServiceProvider);
  return service.getOrCreateCourseProgress(courseId);
});

// Provider to get course progress by ID
final courseProgressByIdProvider = FutureProvider.family<CourseProgressModel?, String>((ref, courseProgressId) async {
  final service = ref.read(courseProgressServiceProvider);
  return service.getCourseProgressById(courseProgressId);
}); 