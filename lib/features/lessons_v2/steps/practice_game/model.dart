class PracticeGameConfig {
  final String title;
  final String instructionText;
  final String instructionAudioUrl;
  final String targetSound;
  final int durationSeconds;
  final int passingScore;
  final List<PracticeGameOption> options;

  const PracticeGameConfig({
    required this.title,
    required this.instructionText,
    required this.instructionAudioUrl,
    required this.targetSound,
    required this.durationSeconds,
    required this.passingScore,
    required this.options,
  });

  factory PracticeGameConfig.fromMap(Map<String, dynamic> map) {
    final options = (map['options'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => PracticeGameOption.fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false);

    return PracticeGameConfig(
      title: map['title'] as String? ?? '',
      instructionText: map['instruction_text'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      targetSound: map['target_sound'] as String? ?? '',
      durationSeconds: map['duration_seconds'] as int? ?? 30,
      passingScore: map['passing_score'] as int? ?? 0,
      options: options.isEmpty
          ? const [
              PracticeGameOption(
                title: '',
                imageUrl: '',
                audioUrl: '',
                isCorrect: false,
              ),
            ]
          : options,
    );
  }
}

class PracticeGameOption {
  final String title;
  final String imageUrl;
  final String audioUrl;
  final bool isCorrect;

  const PracticeGameOption({
    required this.title,
    required this.imageUrl,
    required this.audioUrl,
    required this.isCorrect,
  });

  factory PracticeGameOption.fromMap(Map<String, dynamic> map) {
    return PracticeGameOption(
      title: map['title'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }
}
