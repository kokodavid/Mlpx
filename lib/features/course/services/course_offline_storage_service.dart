import 'dart:convert';
import 'dart:io';

import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:path_provider/path_provider.dart';

const _offlineCoursesDirectoryName = 'offline_courses_v2';
const _courseDataFileName = 'course_data.json';

class CourseOfflineStorageService {
  String _userId() {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  Future<Directory> getCourseDirectory(String courseId) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDirectory.path}/$_offlineCoursesDirectoryName/${_userId()}/$courseId',
    );
  }

  Future<Directory> getOfflineCoursesDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDirectory.path}/$_offlineCoursesDirectoryName/${_userId()}',
    );
  }

  Future<void> saveCompleteCourse(CompleteCourseModel course) async {
    final courseDirectory = await getCourseDirectory(course.course.id);
    if (!await courseDirectory.exists()) {
      await courseDirectory.create(recursive: true);
    }

    final courseDataFile = _courseDataFile(courseDirectory);
    await courseDataFile.writeAsString(jsonEncode(course.toJson()));
  }

  Future<CompleteCourseModel?> readCompleteCourse(String courseId) async {
    try {
      final courseDirectory = await getCourseDirectory(courseId);
      final courseDataFile = _courseDataFile(courseDirectory);
      if (!await courseDataFile.exists()) {
        return null;
      }

      final data = jsonDecode(await courseDataFile.readAsString());
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return CompleteCourseModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<CompleteCourseModel>> listCachedCourses() async {
    final offlineCoursesDirectory = await getOfflineCoursesDirectory();
    if (!await offlineCoursesDirectory.exists()) {
      return <CompleteCourseModel>[];
    }

    final courseDirectories = await offlineCoursesDirectory.list().toList();
    final courses = <CompleteCourseModel>[];
    for (final entity in courseDirectories) {
      if (entity is! Directory) {
        continue;
      }
      final courseDataFile = _courseDataFile(entity);
      if (!await courseDataFile.exists()) {
        continue;
      }
      final course = await readCompleteCourse(_lastPathSegment(entity.path));
      if (course != null) {
        courses.add(course);
      }
    }
    return courses;
  }

  Future<ModuleWithLessons?> readModule(String moduleId) async {
    final courses = await listCachedCourses();
    for (final course in courses) {
      for (final module in course.modules) {
        if (module.module.id == moduleId) {
          return module;
        }
      }
    }
    return null;
  }

  File _courseDataFile(Directory courseDirectory) {
    return File('${courseDirectory.path}/$_courseDataFileName');
  }

  String _lastPathSegment(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}
