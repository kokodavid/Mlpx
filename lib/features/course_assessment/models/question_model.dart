/// Typed model for questions stored in AssessmentSublevel.questions JSONB.
class AssessmentQuestion {
  final String type;
  final String title;
  final String prompt;
  final String? soundInstructionUrl;
  final String? audioFile;
  final List<QuestionOption> options;
  final dynamic correctAnswer;
  final List<String> example;
  final List<MainContentItem> mainContent;
  final Map<String, dynamic> extraFields;

  // Type-specific fields
  final String? targetLetter;
  final String? sentence;
  final String? statement;

  const AssessmentQuestion({
    required this.type,
    required this.title,
    required this.prompt,
    this.soundInstructionUrl,
    this.audioFile,
    this.options = const [],
    this.correctAnswer,
    this.example = const [],
    this.mainContent = const [],
    this.extraFields = const {},
    this.targetLetter,
    this.sentence,
    this.statement,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    final correctAnswer = json['correct_answer'];
    final extraFields = _parseExtraFields(json['extra_fields']);
    return AssessmentQuestion(
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      soundInstructionUrl: json['sound_instruction_url'] as String?,
      audioFile: json['audio_file'] as String?,
      options: _parseOptions(
        json['options'],
        correctAnswer,
      ),
      correctAnswer: correctAnswer,
      example: _parseStringList(json['example']),
      mainContent: _parseMainContent(json['main_content']),
      extraFields: extraFields,
      targetLetter: _asNullableString(json['target_letter']) ??
          _asNullableString(extraFields['target_letter']) ??
          _asNullableString(extraFields['targetLetter']),
      sentence: _asNullableString(json['sentence']) ??
          _asNullableString(extraFields['sentence']),
      statement: _asNullableString(json['statement']) ??
          _asNullableString(extraFields['statement']),
    );
  }

  /// Effective audio URL (prefers sound_instruction_url, falls back to audio_file).
  String get audioUrl => soundInstructionUrl ?? audioFile ?? '';

  /// Optional helper for new V2 payloads.
  String? get hintText => _asNullableString(extraFields['hint_text']);

  /// Flat text values from main content, useful for simple text-first UIs.
  List<String> get mainContentValues =>
      mainContent.map((item) => item.value).toList(growable: false);
}

class QuestionOption {
  final String label;
  final String? imageUrl;
  final bool isCorrect;

  const QuestionOption({
    required this.label,
    this.imageUrl,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      label: _asNullableString(json['label']) ??
          _asNullableString(json['text']) ??
          _asNullableString(json['value']) ??
          '',
      imageUrl: _asNullableString(json['image_url']) ??
          _asNullableString(json['imageUrl']),
      isCorrect: _asBool(json['is_correct']) || _asBool(json['isCorrect']),
    );
  }
}

class MainContentItem {
  final String type;
  final String value;

  const MainContentItem({
    required this.type,
    required this.value,
  });

  factory MainContentItem.fromJson(Map<String, dynamic> json) {
    return MainContentItem(
      type: json['type'] as String? ?? 'text',
      value: json['value'] as String? ?? '',
    );
  }
}

List<QuestionOption> _parseOptions(dynamic rawOptions, dynamic correctAnswer) {
  if (rawOptions is! List) {
    return const [];
  }

  final options = <QuestionOption>[];
  var hasExplicitCorrectFlags = false;

  for (final rawOption in rawOptions) {
    if (rawOption is String) {
      options.add(QuestionOption(label: rawOption));
      continue;
    }

    if (rawOption is Map) {
      final optionMap =
          rawOption.map((key, value) => MapEntry(key.toString(), value));
      final label = _asNullableString(optionMap['label']) ??
          _asNullableString(optionMap['text']) ??
          '';
      final imageUrl = _asNullableString(optionMap['image_url']) ??
          _asNullableString(optionMap['imageUrl']);
      final hasIsCorrectKey = optionMap.containsKey('is_correct') ||
          optionMap.containsKey('isCorrect');
      if (hasIsCorrectKey) {
        hasExplicitCorrectFlags = true;
      }
      final isCorrect =
          _asBool(optionMap['is_correct']) || _asBool(optionMap['isCorrect']);
      options.add(
        QuestionOption(
          label: label,
          imageUrl: imageUrl,
          isCorrect: isCorrect,
        ),
      );
      continue;
    }

    if (rawOption != null) {
      options.add(QuestionOption(label: rawOption.toString()));
    }
  }

  if (hasExplicitCorrectFlags || options.isEmpty) {
    return options;
  }

  if (correctAnswer is num) {
    final correctIndex = correctAnswer.toInt();
    if (correctIndex >= 0 && correctIndex < options.length) {
      return options
          .asMap()
          .entries
          .map(
            (entry) => QuestionOption(
              label: entry.value.label,
              imageUrl: entry.value.imageUrl,
              isCorrect: entry.key == correctIndex,
            ),
          )
          .toList(growable: false);
    }
  }

  final normalizedCorrectAnswers = _normalizedAnswers(correctAnswer);
  if (normalizedCorrectAnswers.isEmpty) {
    return options;
  }

  return options
      .map(
        (option) => QuestionOption(
          label: option.label,
          imageUrl: option.imageUrl,
          isCorrect: normalizedCorrectAnswers.contains(
            _normalizeAnswerValue(option.label),
          ),
        ),
      )
      .toList(growable: false);
}

List<MainContentItem> _parseMainContent(dynamic rawMainContent) {
  if (rawMainContent is! List) {
    return const [];
  }

  final content = <MainContentItem>[];
  for (final rawItem in rawMainContent) {
    if (rawItem is String) {
      content.add(MainContentItem(type: 'text', value: rawItem));
      continue;
    }

    if (rawItem is Map) {
      final itemMap =
          rawItem.map((key, value) => MapEntry(key.toString(), value));
      content.add(MainContentItem.fromJson(itemMap));
      continue;
    }

    if (rawItem != null) {
      content.add(MainContentItem(type: 'text', value: rawItem.toString()));
    }
  }
  return content;
}

Map<String, dynamic> _parseExtraFields(dynamic rawExtraFields) {
  if (rawExtraFields is Map<String, dynamic>) {
    return rawExtraFields;
  }
  if (rawExtraFields is Map) {
    return rawExtraFields.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return const {};
}

List<String> _parseStringList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .where((item) => item != null)
      .map((item) => item.toString())
      .toList(growable: false);
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

Set<String> _normalizedAnswers(dynamic correctAnswer) {
  if (correctAnswer == null) {
    return const {};
  }

  if (correctAnswer is List) {
    return correctAnswer
        .where((value) => value != null)
        .map((value) => _normalizeAnswerValue(value))
        .toSet();
  }

  if (correctAnswer is String && correctAnswer.contains(',')) {
    return correctAnswer
        .split(',')
        .map((value) => _normalizeAnswerValue(value))
        .toSet();
  }

  return {_normalizeAnswerValue(correctAnswer)};
}

String _normalizeAnswerValue(dynamic value) {
  return value.toString().trim().toLowerCase();
}
