import 'package:flutter/foundation.dart';

enum LessonType {
  letter,
  word,
  sentence,
}

enum LessonStepType {
  introduction,
  demonstration,
  practice,
  assessment,
  blending,
  intro,
  soundPronunciation,
  exampleWords,
  soundExplanation,
  soundDiscrimination,
  soundItemMatching,
  soundLetterMatch,
  guidedReading,
  guidedWordReading,
  quickPick,
  soundCheck,
  soundPresenceCheck,
  practiceGame,
  quickCheck,
}

class LessonStepDefinition {
  final String key;
  final LessonStepType type;
  final Map<String, dynamic> config;
  final bool required;

  const LessonStepDefinition({
    required this.key,
    required this.type,
    this.config = const {},
    this.required = true,
  });

  factory LessonStepDefinition.fromSupabase(Map<String, dynamic> row) {
    return LessonStepDefinition(
      key: row['step_key'] as String? ?? '',
      type: _lessonStepTypeFromString(row['step_type'] as String?),
      config: (row['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      required: row['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toSupabase(String lessonId, int position) {
    return {
      'lesson_id': lessonId,
      'step_key': key,
      'step_type': _lessonStepTypeToString(type),
      'position': position,
      'required': required,
      'config': config,
    };
  }
}

class LessonDefinition {
  final String id;
  final String moduleId;
  final LessonType lessonType;
  final String title;
  final String progressLabel;
  final List<LessonStepDefinition> steps;
  final int displayOrder;

  const LessonDefinition({
    this.id = '',
    this.moduleId = '',
    required this.lessonType,
    required this.title,
    required this.steps,
    this.progressLabel = 'Lesson Progress',
    this.displayOrder = 0,
  });

  factory LessonDefinition.fromSupabase(
    Map<String, dynamic> lessonRow,
    List<Map<String, dynamic>> stepRows,
  ) {
    return LessonDefinition(
      id: lessonRow['id'] as String? ?? '',
      moduleId: lessonRow['module_id'] as String? ?? '',
      lessonType: _lessonTypeFromString(lessonRow['lesson_type'] as String?),
      title: lessonRow['title'] as String? ?? '',
      displayOrder: lessonRow['display_order'] as int? ?? 0,
      steps: stepRows
          .map(LessonStepDefinition.fromSupabase)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id.isEmpty ? null : id,
      'module_id': moduleId,
      'lesson_type': lessonType.name,
      'title': title,
      'display_order': displayOrder,
    };
  }

  factory LessonDefinition.demoLetterA() {
    return const LessonDefinition(
      lessonType: LessonType.letter,
      title: 'Letter A a',
      progressLabel: 'Letter Progress',
      steps: [
        LessonStepDefinition(
          key: 'sound',
          type: LessonStepType.introduction,
          config: {
            'title': 'Sound Pronunciation',
            'display_text': 'Aa',
            'practice_tip': {
              'text': 'Practice: Watch your mouth in a mirror while making this sound. Try saying "apple" slowly – notice how your mouth opens wide for the "a" sound.',
              'audio_url': '',
            },
          },
        ),
        LessonStepDefinition(
          key: 'formation',
          type: LessonStepType.demonstration,
          config: {
            'title': 'Letter Formation',
            'feedbackTitle': 'Great tracing!',
            'feedbackBody': "You're forming the letter well. Keep practicing!",
          },
        ),
        LessonStepDefinition(
          key: 'examples',
          type: LessonStepType.practice,
          config: {
            'title': 'Example Words',
            'tip':
                'Tip: Say each word out loud after hearing it. Focus on the highlighted letter sound.',
            'examples': [
              {'word': 'Apple'},
              {'word': 'Ant'},
              {'word': 'Alligator'},
              {'word': 'Arrow'},
            ],
          },
        ),
        LessonStepDefinition(
          key: 'exercise',
          type: LessonStepType.assessment,
          config: {
            'title': 'Letter Exercise',
            'prompt': 'Tap all items that start with the "Aa" sound',
            'hint': 'Select all correct answers, then tap "Check Answers".',
            'options': [
              {'label': 'Apple'},
              {'label': 'Ball'},
              {'label': 'Ant'},
              {'label': 'Car'},
              {'label': 'Anchor'},
              {'label': 'Cat'},
            ],
          },
        ),
      ],
    );
  }

  factory LessonDefinition.debugCourse2Lesson1Preview({
    String id = 'debug-course-2-lesson-1',
    String moduleId = '',
    String title = 'Course 2 Lesson 1 Preview',
  }) {
    return LessonDefinition(
      id: id,
      moduleId: moduleId,
      lessonType: LessonType.word,
      title: title,
      progressLabel: 'Word Progress',
      steps: const [
        LessonStepDefinition(
          key: 'sound-pronunciation',
          type: LessonStepType.soundPronunciation,
          config: {
            'display_text': 'Aa',
            'phoneme_display': 'a',
            'phoneme_label': '/a/ as in "apple"',
            'how_to_title': 'How to make this sound',
            'practice_tip': {
              'text':
                  'Focus on the short a sound. Open your mouth and say it clearly.',
              'audio_url': '',
            },
            'audio': {
              'base_url': '',
              'speed_variants': {
                '0.5x': '',
                '1x': '',
                '1.5x': '',
              },
            },
          },
        ),
        LessonStepDefinition(
          key: 'example-words',
          type: LessonStepType.exampleWords,
          config: {
            'phoneme': '/a/',
            'practice_tip': {
              'text':
                  'Say each word and notice where you hear the short a sound.',
              'audio_url': '',
            },
            'prompt_text': 'Your turn: say /a/',
            'helper_text': 'Tap to start recording.\nSay /a/ out loud.',
            'words': [
              {'label': 'apple', 'image_url': '', 'audio_url': ''},
              {'label': 'cat', 'image_url': '', 'audio_url': ''},
              {'label': 'map', 'image_url': '', 'audio_url': ''},
              {'label': 'bag', 'image_url': '', 'audio_url': ''},
            ],
          },
        ),
        LessonStepDefinition(
          key: 'sound-discrimination',
          type: LessonStepType.soundDiscrimination,
          config: {
            'target_sound': 'a',
            'reference_word': 'apple',
            'tip_text': 'Listen carefully for the /a/ sound.',
            'items': [
              {
                'word': 'cat',
                'title_audio_url': '',
                'image_url': '',
                'contains_target_sound': true,
              },
            ],
          },
        ),
        LessonStepDefinition(
          key: 'sound-match',
          type: LessonStepType.soundItemMatching,
          config: {
            'activities': [
              {
                'tip_text': 'Tap the word that matches the sound you hear.',
                'content_audio_url': '',
                'options': [
                  {'label': 'cat', 'is_correct': true},
                  {'label': 'pen', 'is_correct': false},
                  {'label': 'bus', 'is_correct': false},
                ],
              },
            ],
          },
        ),
        LessonStepDefinition(
          key: 'guided-reading',
          type: LessonStepType.guidedReading,
          config: {
            'instruction_text': 'Listen to each sound, then read the word.',
            'activities': [
              {
                'word_text': 'cat',
                'word_audio_url': '',
                'segments': [
                  {
                    'phoneme_label': '/k/',
                    'grapheme': 'c',
                    'audio_url': '',
                    'is_focus': false,
                  },
                  {
                    'phoneme_label': '/a/',
                    'grapheme': 'a',
                    'audio_url': '',
                    'is_focus': true,
                  },
                  {
                    'phoneme_label': '/t/',
                    'grapheme': 't',
                    'audio_url': '',
                    'is_focus': false,
                  },
                ],
              },
            ],
            'target_sound': 'a',
          },
        ),
        LessonStepDefinition(
          key: 'quick-pick',
          type: LessonStepType.quickPick,
          config: {
            'title': 'Quick Pick: /a/ Words',
            'instruction_text': 'Tap all the words that have the /a/ sound.',
            'duration_seconds': 30,
            'options': [
              {'title': 'apple', 'image_url': '', 'audio_url': '', 'is_correct': true},
              {'title': 'cat', 'image_url': '', 'audio_url': '', 'is_correct': true},
              {'title': 'bus', 'image_url': '', 'audio_url': '', 'is_correct': false},
              {'title': 'pen', 'image_url': '', 'audio_url': '', 'is_correct': false},
            ],
          },
        ),
        LessonStepDefinition(
          key: 'sound-check',
          type: LessonStepType.soundPresenceCheck,
          config: {
            'questions': [
              {
                'prompt': 'Does "apple" have the /a/ sound?',
                'word_audio_url': '',
                'correct_answer': true,
              },
            ],
          },
        ),
      ],
    );
  }
}

class LessonStepUiState {
  final bool? canAdvance;
  final bool? isPrimaryEnabled;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool? showBack;

  const LessonStepUiState({
    this.canAdvance,
    this.isPrimaryEnabled,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.showBack,
  });
}

LessonType _lessonTypeFromString(String? value) {
  switch (value) {
    case 'word':
      return LessonType.word;
    case 'sentence':
      return LessonType.sentence;
    case 'letter':
    default:
      return LessonType.letter;
  }
}

LessonStepType _lessonStepTypeFromString(String? value) {
  switch (value) {
    case 'intro':
      return LessonStepType.intro;
    case 'sound_pronunciation':
      return LessonStepType.soundPronunciation;
    case 'example_words':
      return LessonStepType.exampleWords;
    case 'sound_explanation':
      return LessonStepType.soundExplanation;
    case 'blending':
      return LessonStepType.blending;
    case 'sound_discrimination':
      return LessonStepType.soundDiscrimination;
    case 'sound_item_matching':
      return LessonStepType.soundItemMatching;
    case 'sound_letter_match':
      return LessonStepType.soundLetterMatch;
    case 'guided_reading':
      return LessonStepType.guidedReading;
    case 'guided reading':
      return LessonStepType.guidedReading;
    case 'guided_word_reading':
      return LessonStepType.guidedWordReading;
    case 'quick_pick':
      return LessonStepType.quickPick;
    case 'sound_check':
      return LessonStepType.soundCheck;
    case 'sound_presence_check':
      return LessonStepType.soundPresenceCheck;
    case 'practice_game':
      return LessonStepType.practiceGame;
    case 'quick_check':
      return LessonStepType.quickCheck;
    case 'demonstration':
      return LessonStepType.demonstration;
    case 'practice':
      return LessonStepType.practice;
    case 'assessment':
      return LessonStepType.assessment;
    case 'introduction':
    default:
      return LessonStepType.introduction;
  }
}

String _lessonStepTypeToString(LessonStepType value) {
  switch (value) {
    case LessonStepType.intro:
      return 'intro';
    case LessonStepType.soundPronunciation:
      return 'sound_pronunciation';
    case LessonStepType.exampleWords:
      return 'example_words';
    case LessonStepType.soundExplanation:
      return 'sound_explanation';
    case LessonStepType.blending:
      return 'blending';
    case LessonStepType.soundDiscrimination:
      return 'sound_discrimination';
    case LessonStepType.soundItemMatching:
      return 'sound_item_matching';
    case LessonStepType.soundLetterMatch:
      return 'sound_letter_match';
    case LessonStepType.guidedReading:
      return 'guided_reading';
    case LessonStepType.guidedWordReading:
      return 'guided_word_reading';
    case LessonStepType.quickPick:
      return 'quick_pick';
    case LessonStepType.soundCheck:
      return 'sound_check';
    case LessonStepType.soundPresenceCheck:
      return 'sound_presence_check';
    case LessonStepType.practiceGame:
      return 'practice_game';
    case LessonStepType.quickCheck:
      return 'quick_check';
    case LessonStepType.demonstration:
      return 'demonstration';
    case LessonStepType.practice:
      return 'practice';
    case LessonStepType.assessment:
      return 'assessment';
    case LessonStepType.introduction:
      return 'introduction';
  }
}
