import 'package:flutter/material.dart';
import '../models/lesson_models.dart';
import '../steps/assessment_step.dart';
import '../steps/blending_step.dart';
import '../steps/demonstration_step.dart';
import '../steps/guided_reading_step.dart';
import '../steps/introduction_step.dart';
import '../steps/matching_words_step.dart';
import '../steps/mini_story_card_step.dart';
import '../steps/missing_letters_step.dart';
import '../steps/practice_game_step.dart';
import '../steps/practice_step.dart';
import '../steps/sentence_reading_step.dart';
import '../steps/sound_discrimination_step.dart';
import '../steps/sound_item_matching_step.dart';
import '../steps/sound_presence_check_step.dart';
import '../steps/word_reading_step.dart';

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
      case LessonStepType.blending:
        return BlendingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.soundDiscrimination:
        return SoundDiscriminationStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.soundItemMatching:
        return SoundItemMatchingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.guidedReading:
        return GuidedReadingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.practiceGame:
        return PracticeGameStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.soundPresenceCheck:
        return SoundPresenceCheckStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.missingLetters:
        return MissingLettersStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.matchingWords:
        return MatchingWordsStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.wordReading:
        return WordReadingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.sentenceReading:
        return SentenceReadingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.miniStoryCard:
        return MiniStoryCardStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
    }
  }
}
