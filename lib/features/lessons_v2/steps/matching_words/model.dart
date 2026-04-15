enum MatchingMode {
  soundToImage,
  soundToWord,
  imageToWord;

  static MatchingMode fromValue(String? value) {
    switch (value) {
      case 'sound_to_image':
        return MatchingMode.soundToImage;
      case 'image_to_word':
        return MatchingMode.imageToWord;
      case 'sound_to_word':
      default:
        return MatchingMode.soundToWord;
    }
  }
}

class MatchingWordsConfig {
  final String title;
  final String instructionAudioUrl;
  final List<MatchingActivity> activities;

  const MatchingWordsConfig({
    required this.title,
    required this.instructionAudioUrl,
    required this.activities,
  });

  factory MatchingWordsConfig.fromMap(Map<String, dynamic> map) {
    final rawActivities = map['activities'] as List<dynamic>? ?? const [];

    return MatchingWordsConfig(
      title: map['title'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      activities: rawActivities
          .whereType<Map>()
          .map(
            (item) => MatchingActivity.fromMap(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class MatchingActivity {
  final MatchingMode mode;
  final String promptText;
  final String promptAudioUrl;
  final String promptImageUrl;
  final String correctOptionId;
  final List<MatchingOption> options;

  const MatchingActivity({
    required this.mode,
    required this.promptText,
    required this.promptAudioUrl,
    required this.promptImageUrl,
    required this.correctOptionId,
    required this.options,
  });

  factory MatchingActivity.fromMap(Map<String, dynamic> map) {
    final options = (map['options'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => MatchingOption.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);

    return MatchingActivity(
      mode: MatchingMode.fromValue(map['mode'] as String?),
      promptText: map['prompt_text'] as String? ?? '',
      promptAudioUrl: map['prompt_audio_url'] as String? ?? '',
      promptImageUrl: map['prompt_image_url'] as String? ?? '',
      correctOptionId: map['correct_option_id'] as String? ??
          (options.isNotEmpty ? options.first.id : ''),
      options: options,
    );
  }
}

class MatchingOption {
  final String id;
  final String label;
  final String imageUrl;

  const MatchingOption({
    required this.id,
    required this.label,
    required this.imageUrl,
  });

  factory MatchingOption.fromMap(Map<String, dynamic> map) {
    return MatchingOption(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
    );
  }
}
