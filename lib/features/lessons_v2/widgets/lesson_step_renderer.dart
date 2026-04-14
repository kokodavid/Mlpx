import 'package:flutter/material.dart';
import '../models/lesson_models.dart';
import '../steps/assessment_step.dart';
import '../steps/demonstration_step.dart';
import '../steps/example_words_step.dart';
import '../steps/guided_word_reading_step.dart';
import '../steps/introduction_step.dart';
import '../steps/practice_step.dart';
import '../steps/quick_pick_step.dart';
import '../steps/sound_pronunciation_step.dart';
import '../steps/sound_check_step.dart';
import '../steps/sound_discrimination_step.dart';
import '../steps/sound_letter_match_step.dart';

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
      case LessonStepType.intro:
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
      case LessonStepType.soundPronunciation:
        return SoundPronunciationStep(
          step: step,
          onStepStateChanged: onStepStateChanged,
        );
      case LessonStepType.exampleWords:
      case LessonStepType.soundExplanation:
        final phoneme = step.config['phoneme'] as String? ?? '/a/';
        final practiceTipMap =
            (step.config['practice_tip'] as Map?)?.cast<String, dynamic>() ??
                {};
        final wordItems = (step.config['words'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .map(
              (item) => ExampleWordItem(
                label: item['label'] as String? ?? '',
                imageUrl: item['image_url'] as String? ?? '',
                audioUrl: item['audio_url'] as String? ?? '',
              ),
            )
            .toList(growable: false);
        return ExampleWordsStep(
          items: wordItems,
          highlightedLetter: phoneme.replaceAll('/', ''),
          tipText: practiceTipMap['text'] as String? ??
              'Tip: Say each word out loud after hearing it. Focus on the highlighted letter sound.',
          tipAudioUrl: practiceTipMap['audio_url'] as String? ?? '',
          promptText:
              step.config['prompt_text'] as String? ?? 'Your turn: say $phoneme',
          helperText: step.config['helper_text'] as String? ??
              'Tap to start recording.\nYour turn - say $phoneme out loud',
        );
      case LessonStepType.soundDiscrimination:
        final items = (step.config['items'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        final firstItem =
            items.isNotEmpty ? items.first : const <String, dynamic>{};
        final targetSound = step.config['target_sound'] as String? ?? 'a';
        final referenceWord =
            step.config['reference_word'] as String? ?? 'apple';
        return SoundDiscriminationStep(
          question:
              step.config['question'] as String? ?? 'Does it have /$targetSound/?',
          imageUrl: firstItem['image_url'] as String? ?? '',
          word: firstItem['word'] as String? ?? '',
          audioUrl: firstItem['title_audio_url'] as String? ?? '',
          tipText: step.config['tip_text'] as String? ??
              "Tip: Listen to the word. Does it have the /$targetSound/ sound, like in '$referenceWord'?",
          activityLabel:
              step.config['activity_label'] as String? ?? 'Activity 1 of ${items.isEmpty ? 1 : items.length}',
          progressPercent: step.config['progress_percent'] as int? ??
              (items.isEmpty ? 0 : (100 / items.length).round()),
          correctAnswer: firstItem['has_sound'] as bool? ??
              firstItem['contains_target_sound'] as bool? ??
              false,
        );
      case LessonStepType.soundItemMatching:
      case LessonStepType.soundLetterMatch:
        final activities = (step.config['activities'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        final firstActivity =
            activities.isNotEmpty ? activities.first : const <String, dynamic>{};
        final options = (firstActivity['options'] as List<dynamic>? ?? [])
            .map((item) {
              if (item is Map) {
                final map = item.cast<String, dynamic>();
                return map['label'] as String? ?? '';
              }
              return item.toString();
            })
            .toList(growable: false);
        return SoundLetterMatchStep(
          activityLabel:
              firstActivity['activity_label'] as String? ?? 'Activity 1 of ${activities.isEmpty ? 1 : activities.length}',
          progressPercent: firstActivity['progress_percent'] as int? ??
              (activities.isEmpty ? 0 : (100 / activities.length).round()),
          score: firstActivity['score'] as int? ?? 0,
          totalScore: firstActivity['total_score'] as int? ?? activities.length,
          audioUrl: firstActivity['audio_url'] as String? ??
              firstActivity['content_audio_url'] as String? ??
              firstActivity['prompt_audio_url'] as String? ??
              '',
          tipText: firstActivity['tip_text'] as String? ??
              'Tip: Find the ${(step.config['target_sound'] as String? ?? '/a/')} sound',
          options: options,
          correctOption: firstActivity['correct_option'] as String? ??
              ((firstActivity['options'] as List<dynamic>? ?? [])
                  .whereType<Map>()
                  .map((item) => item.cast<String, dynamic>())
                  .firstWhere(
                    (item) => item['is_correct'] as bool? ?? false,
                    orElse: () => const <String, dynamic>{},
                  )['label'] as String? ??
                  ''),
        );
      case LessonStepType.blending:
      case LessonStepType.guidedReading:
      case LessonStepType.guidedWordReading:
        final words = (step.config['words'] as List<dynamic>? ??
                step.config['examples'] as List<dynamic>? ??
                step.config['activities'] as List<dynamic>? ??
                [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        final firstWord =
            words.isNotEmpty ? words.first : const <String, dynamic>{};
        final phonemes = (firstWord['phonemes'] as List<dynamic>? ??
                firstWord['segments'] as List<dynamic>? ??
                [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        final highlightedIndex = phonemes.indexWhere(
          (item) => item['is_focus'] as bool? ?? item['highlighted'] as bool? ?? false,
        );
        final phonemeLabels = phonemes
            .map(
              (item) =>
                  item['label'] as String? ??
                  item['phoneme_label'] as String? ??
                  item['grapheme'] as String? ??
                  '',
            )
            .toList(growable: false);
        return GuidedWordReadingStep(
          instruction: step.config['instruction'] as String? ??
              step.config['instruction_text'] as String? ??
              'Listen to the sounds. Then hear the whole word',
          audioUrl: firstWord['word_audio_url'] as String? ??
              firstWord['instruction_audio_url'] as String? ??
              '',
          phonemes: phonemeLabels,
          highlightedIndex: highlightedIndex < 0 ? 0 : highlightedIndex,
          word: firstWord['word'] as String? ??
              firstWord['word_text'] as String? ??
              '',
          vowelLetter: step.config['vowel_letter'] as String? ??
              step.config['target_sound'] as String? ??
              'a',
        );
      case LessonStepType.quickPick:
      case LessonStepType.practiceGame:
        final options = (step.config['options'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .map(
              (item) => QuickPickItem(
                label: item['label'] as String? ?? item['title'] as String? ?? '',
                imageUrl: item['image_url'] as String? ?? '',
                audioUrl: item['audio_url'] as String? ?? '',
                isCorrect: item['is_correct'] as bool? ?? false,
              ),
            )
            .toList(growable: false);
        return QuickPickStep(
          title:
              step.config['title'] as String? ?? 'Quick Pick: /a/ Words',
          instruction: step.config['instruction'] as String? ??
              step.config['instruction_text'] as String? ??
              'Tap the word with /a/ sound. skip the others',
          timerSeconds: step.config['duration_seconds'] as int? ?? 60,
          items: options,
        );
      case LessonStepType.soundPresenceCheck:
      case LessonStepType.soundCheck:
      case LessonStepType.quickCheck:
        final questions = (step.config['questions'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
        final firstQuestion =
            questions.isNotEmpty ? questions.first : const <String, dynamic>{};
        return SoundCheckStep(
          questionLabel:
              firstQuestion['question_label'] as String? ?? 'Question 1 of ${questions.isEmpty ? 1 : questions.length}',
          progressPercent: firstQuestion['progress_percent'] as int? ??
              (questions.isEmpty ? 0 : (100 / questions.length).round()),
          score: firstQuestion['score'] as int? ?? 0,
          totalScore:
              step.config['passing_score'] as int? ?? questions.length,
          question: firstQuestion['question'] as String? ??
              firstQuestion['prompt'] as String? ??
              '',
          audioUrl: firstQuestion['audio_url'] as String? ??
              firstQuestion['word_audio_url'] as String? ??
              firstQuestion['prompt_audio_url'] as String? ??
              '',
          correctAnswer: firstQuestion['correct_answer'] as bool? ?? true,
        );
    }
  }
}
