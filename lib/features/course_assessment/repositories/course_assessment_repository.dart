import 'package:flutter/foundation.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/course_assessment_model.dart';
import '../models/assessment_level_model.dart';
import '../models/assessment_sublevel_model.dart';
import '../models/assessment_v2_progress_model.dart';
import '../models/assessment_v2_composites.dart';

class CourseAssessmentRepository {
  /// Fetch the full assessment tree for a course:
  /// CourseAssessment → Levels (ordered) → Sublevels (ordered, with questions)
  Future<AssessmentWithLevels?> fetchAssessmentByCourseId(
      String courseId) async {
    try {
      // 1. Fetch the course assessment
      final assessmentRow = await SupabaseConfig.client
          .from('course_assessments')
          .select()
          .eq('course_id', courseId)
          .maybeSingle();

      if (assessmentRow == null) {
        debugPrint(
            'CourseAssessmentRepository: No assessment found for course $courseId');
        return null;
      }

      final assessment = CourseAssessment.fromJson(assessmentRow);

      // 2. Fetch all levels for this assessment
      final levelRows = await SupabaseConfig.client
          .from('assessment_levels')
          .select()
          .eq('assessment_id', assessment.id)
          .order('display_order', ascending: true);

      final levels = (levelRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => AssessmentLevel.fromJson(row))
          .toList();

      // 3. Fetch all sublevels for all levels in one query
      final levelIds = levels.map((l) => l.id).toList();
      if (levelIds.isEmpty) {
        return AssessmentWithLevels(
          assessment: assessment,
          levels: [],
        );
      }

      final sublevelRows = await SupabaseConfig.client
          .from('assessment_sublevels')
          .select()
          .inFilter('level_id', levelIds)
          .order('display_order', ascending: true);

      final sublevels = (sublevelRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => AssessmentSublevel.fromJson(row))
          .toList();

      // 4. Group sublevels by level_id
      final sublevelsByLevel = <String, List<AssessmentSublevel>>{};
      for (final sublevel in sublevels) {
        sublevelsByLevel
            .putIfAbsent(sublevel.levelId, () => [])
            .add(sublevel);
      }

      // 5. Build the composite tree
      final levelsWithSublevels = levels
          .map((level) => LevelWithSublevels(
                level: level,
                sublevels: sublevelsByLevel[level.id] ?? [],
              ))
          .toList();

      return AssessmentWithLevels(
        assessment: assessment,
        levels: levelsWithSublevels,
      );
    } catch (e) {
      debugPrint(
          'CourseAssessmentRepository: Failed to fetch assessment for course $courseId: $e');
      return null;
    }
  }

  /// Fetch the assessment by its ID directly
  Future<AssessmentWithLevels?> fetchAssessmentById(
      String assessmentId) async {
    try {
      final assessmentRow = await SupabaseConfig.client
          .from('course_assessments')
          .select()
          .eq('id', assessmentId)
          .maybeSingle();

      if (assessmentRow == null) return null;

      final assessment = CourseAssessment.fromJson(assessmentRow);

      // Reuse the same tree-building logic
      final levelRows = await SupabaseConfig.client
          .from('assessment_levels')
          .select()
          .eq('assessment_id', assessmentId)
          .order('display_order', ascending: true);

      final levels = (levelRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => AssessmentLevel.fromJson(row))
          .toList();

      final levelIds = levels.map((l) => l.id).toList();
      if (levelIds.isEmpty) {
        return AssessmentWithLevels(assessment: assessment, levels: []);
      }

      final sublevelRows = await SupabaseConfig.client
          .from('assessment_sublevels')
          .select()
          .inFilter('level_id', levelIds)
          .order('display_order', ascending: true);

      final sublevels = (sublevelRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => AssessmentSublevel.fromJson(row))
          .toList();

      final sublevelsByLevel = <String, List<AssessmentSublevel>>{};
      for (final sublevel in sublevels) {
        sublevelsByLevel
            .putIfAbsent(sublevel.levelId, () => [])
            .add(sublevel);
      }

      final levelsWithSublevels = levels
          .map((level) => LevelWithSublevels(
                level: level,
                sublevels: sublevelsByLevel[level.id] ?? [],
              ))
          .toList();

      return AssessmentWithLevels(
        assessment: assessment,
        levels: levelsWithSublevels,
      );
    } catch (e) {
      debugPrint(
          'CourseAssessmentRepository: Failed to fetch assessment $assessmentId: $e');
      return null;
    }
  }

  /// Fetch all progress entries for a user on a given assessment
  Future<List<AssessmentV2Progress>> fetchProgress(
      String assessmentId) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      final rows = await SupabaseConfig.client
          .from('assessment_v2_progress')
          .select()
          .eq('user_id', userId)
          .eq('assessment_id', assessmentId);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => AssessmentV2Progress.fromJson(row))
          .toList();
    } catch (e) {
      debugPrint(
          'CourseAssessmentRepository: Failed to fetch progress for assessment $assessmentId: $e');
      return [];
    }
  }

  /// Save or update progress for a sublevel (upsert by user_id + sublevel_id)
  Future<AssessmentV2Progress?> saveProgress(
      AssessmentV2Progress progress) async {
    try {
      final data = progress.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await SupabaseConfig.client
          .from('assessment_v2_progress')
          .upsert(
            data,
            onConflict: 'user_id,sublevel_id',
          )
          .select()
          .single();

      return AssessmentV2Progress.fromJson(response);
    } catch (e) {
      debugPrint(
          'CourseAssessmentRepository: Failed to save progress: $e');
      return null;
    }
  }
}
