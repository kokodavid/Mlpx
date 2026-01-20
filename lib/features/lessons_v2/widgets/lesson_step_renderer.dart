import 'package:flutter/material.dart';
import '../models/lesson_models.dart';
import '../steps/assessment_step.dart';
import '../steps/demonstration_step.dart';
import '../steps/introduction_step.dart';
import '../steps/practice_step.dart';

class LessonStepRenderer extends StatelessWidget {
  final LessonStepDefinition step;
  final String lessonId;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final bool isLastStep;

  const LessonStepRenderer({
    super.key,
    required this.step,
    required this.lessonId,
    required this.onStepStateChanged,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context) {
    switch (step.type) {
      case LessonStepType.introduction:
        return IntroductionStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.demonstration:
        return DemonstrationStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.practice:
        return PracticeStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.assessment:
        return AssessmentStep(
          step: step,
          lessonId: lessonId,
          onStepStateChanged: onStepStateChanged,
          isLastStep: isLastStep,
        );
    }
  }
}
