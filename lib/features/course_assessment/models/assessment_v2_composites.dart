import 'course_assessment_model.dart';
import 'assessment_level_model.dart';
import 'assessment_sublevel_model.dart';

class LevelWithSublevels {
  final AssessmentLevel level;
  final List<AssessmentSublevel> sublevels;

  const LevelWithSublevels({
    required this.level,
    required this.sublevels,
  });
}

class AssessmentWithLevels {
  final CourseAssessment assessment;
  final List<LevelWithSublevels> levels;

  const AssessmentWithLevels({
    required this.assessment,
    required this.levels,
  });
}
