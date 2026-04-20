class MissingLettersConfig {
  final String title;
  final String instructionText;
  final String instructionAudioUrl;
  final List<MissingLettersActivity> activities;

  const MissingLettersConfig({
    required this.title,
    required this.instructionText,
    required this.instructionAudioUrl,
    required this.activities,
  });

  factory MissingLettersConfig.fromMap(Map<String, dynamic> map) {
    final rawActivities = map['activities'] as List<dynamic>? ?? const [];

    return MissingLettersConfig(
      title: map['title'] as String? ?? '',
      instructionText: map['instruction_text'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      activities: rawActivities
          .whereType<Map>()
          .map(
            (item) =>
                MissingLettersActivity.fromMap(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class MissingLettersActivity {
  final String promptText;
  final String targetWord;
  final List<AnswerSlotDefinition> answerTemplate;
  final List<String> options;

  const MissingLettersActivity({
    required this.promptText,
    required this.targetWord,
    required this.answerTemplate,
    required this.options,
  });

  factory MissingLettersActivity.fromMap(Map<String, dynamic> map) {
    final rawTemplate =
        map['answer_template'] as List<dynamic>? ?? const <dynamic>[];
    final rawOptions = map['options'] as List<dynamic>? ?? const <dynamic>[];

    return MissingLettersActivity(
      promptText: map['prompt_text'] as String? ?? '',
      targetWord: map['target_word'] as String? ?? '',
      answerTemplate: rawTemplate
          .whereType<Map>()
          .map(
            (item) => AnswerSlotDefinition.fromMap(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      options: rawOptions
          .map((item) {
            if (item is String) {
              return item;
            }
            if (item is Map) {
              final typed = item.cast<String, dynamic>();
              return typed['label'] as String? ??
                  typed['value'] as String? ??
                  '';
            }
            return '';
          })
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class AnswerSlotDefinition {
  final String value;
  final AnswerSlotType type;

  const AnswerSlotDefinition({
    required this.value,
    required this.type,
  });

  bool get isGiven => type == AnswerSlotType.given;

  bool get isMissing => type == AnswerSlotType.missing;

  factory AnswerSlotDefinition.fromMap(Map<String, dynamic> map) {
    return AnswerSlotDefinition(
      value: map['value'] as String? ?? '',
      type: AnswerSlotTypeX.fromMap(map),
    );
  }
}

enum AnswerSlotType {
  given,
  missing,
}

extension AnswerSlotTypeX on AnswerSlotType {
  static AnswerSlotType fromMap(Map<String, dynamic> map) {
    if (map['is_missing'] == true) {
      return AnswerSlotType.missing;
    }
    if (map['is_given'] == true) {
      return AnswerSlotType.given;
    }

    final type = (map['type'] ?? map['kind']) as String?;
    switch (type) {
      case 'missing':
        return AnswerSlotType.missing;
      case 'given':
      default:
        return AnswerSlotType.given;
    }
  }
}
