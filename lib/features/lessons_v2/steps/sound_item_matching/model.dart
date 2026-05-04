class SoundItemMatchingConfig {
  final String title;
  final List<SoundItemMatchingActivity> activities;

  const SoundItemMatchingConfig({
    required this.title,
    required this.activities,
  });

  factory SoundItemMatchingConfig.fromMap(Map<String, dynamic> map) {
    final activities = (map['activities'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((activity) => SoundItemMatchingActivity.fromMap(
              activity.cast<String, dynamic>(),
            ))
        .toList(growable: false);

    return SoundItemMatchingConfig(
      title: map['title'] as String? ?? '',
      activities: activities.isEmpty
          ? const [
              SoundItemMatchingActivity(
                prompt: '',
                promptAudioUrl: '',
                contentAudioUrl: '',
                targetSound: '',
                tipText: '',
                options: [
                  SoundItemMatchingOption(label: '', isCorrect: false),
                ],
              ),
            ]
          : activities,
    );
  }
}

class SoundItemMatchingActivity {
  final String prompt;
  final String promptAudioUrl;
  final String contentAudioUrl;
  final String targetSound;
  final String tipText;
  final List<SoundItemMatchingOption> options;

  const SoundItemMatchingActivity({
    required this.prompt,
    required this.promptAudioUrl,
    required this.contentAudioUrl,
    required this.targetSound,
    required this.tipText,
    required this.options,
  });

  factory SoundItemMatchingActivity.fromMap(Map<String, dynamic> map) {
    final options = (map['options'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((option) => SoundItemMatchingOption.fromMap(
              option.cast<String, dynamic>(),
            ))
        .toList(growable: false);

    return SoundItemMatchingActivity(
      prompt: map['prompt'] as String? ?? '',
      promptAudioUrl: map['prompt_audio_url'] as String? ?? '',
      contentAudioUrl: map['content_audio_url'] as String? ?? '',
      targetSound: map['target_sound'] as String? ?? '',
      tipText: map['tip_text'] as String? ?? '',
      options: options.isEmpty
          ? const [SoundItemMatchingOption(label: '', isCorrect: false)]
          : options,
    );
  }

  String get displayTargetSound {
    final normalized = targetSound.replaceAll(RegExp(r'^/+|/+$'), '').trim();
    return normalized.isEmpty ? '' : '/$normalized/';
  }
}

class SoundItemMatchingOption {
  final String label;
  final bool isCorrect;

  const SoundItemMatchingOption({
    required this.label,
    required this.isCorrect,
  });

  factory SoundItemMatchingOption.fromMap(Map<String, dynamic> map) {
    return SoundItemMatchingOption(
      label: map['label'] as String? ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }
}
