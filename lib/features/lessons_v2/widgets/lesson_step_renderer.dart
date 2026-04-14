import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../models/lesson_models.dart';
import '../steps/assessment/assessment_step.dart';
import '../steps/blending/blending_step.dart';
import '../steps/demonstration/demonstration_step.dart';
import '../steps/guided_reading/guided_reading_step.dart';
import '../steps/introduction/introduction_step.dart';
import '../steps/matching_words/matching_words_step.dart';
import '../steps/mini_story_card/mini_story_card_step.dart';
import '../steps/missing_letters/missing_letters_step.dart';
import '../steps/practice/practice_step.dart';
import '../steps/practice_game/practice_game_step.dart';
import '../steps/sentence_reading/sentence_reading_step.dart';
import '../steps/sound_discrimination/sound_discrimination_step.dart';
import '../steps/sound_item_matching/sound_item_matching_step.dart';
import '../steps/sound_presence_check/sound_presence_check_step.dart';
import '../steps/word_reading/word_reading_step.dart';

class LessonStepRenderer extends StatelessWidget {
  final LessonStepDefinition step;
  final String lessonId;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final bool isLastStep;
  final VoidCallback onAdvanceRequested;

  const LessonStepRenderer({
    super.key,
    required this.step,
    required this.lessonId,
    required this.onStepStateChanged,
    required this.isLastStep,
    required this.onAdvanceRequested,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '[LessonStep] lessonId=$lessonId  key=${step.key}  type=${step.type.name}\n'
        'config: ${step.config}',
      );
    }
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
          onAdvanceRequested: onAdvanceRequested,
        );
      case LessonStepType.soundItemMatching:
        return SoundItemMatchingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
          onAdvanceRequested: onAdvanceRequested,
        );
      case LessonStepType.guidedReading:
        return GuidedReadingStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
          onAdvanceRequested: onAdvanceRequested,
        );
      case LessonStepType.practiceGame:
        return PracticeGameStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
          onAdvanceRequested: onAdvanceRequested,
        );
      case LessonStepType.soundPresenceCheck:
        return SoundPresenceCheckStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
          onAdvanceRequested: onAdvanceRequested,
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
