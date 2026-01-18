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
      'step_type': type.name,
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
            'practiceTip':
                'Practice: Watch your mouth in a mirror while making this sound.',
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
