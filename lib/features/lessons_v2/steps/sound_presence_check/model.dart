class SoundPresenceCheckConfig {
  final String title;
  final List<SoundPresenceQuestion> questions;

  const SoundPresenceCheckConfig({
    required this.title,
    required this.questions,
  });

  factory SoundPresenceCheckConfig.fromMap(Map<String, dynamic> map) {
    final questions = (map['questions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => SoundPresenceQuestion.fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false);

    return SoundPresenceCheckConfig(
      title: map['title'] as String? ?? '',
      questions: questions.isEmpty
          ? const [
              SoundPresenceQuestion(
                prompt: '',
                promptAudioUrl: '',
                wordText: '',
                wordAudioUrl: '',
                targetSound: '',
                correctAnswer: false,
                yesLabel: 'Yes',
                noLabel: 'No',
              ),
            ]
          : questions,
    );
  }
}

class SoundPresenceQuestion {
  final String prompt;
  final String promptAudioUrl;
  final String wordText;
  final String wordAudioUrl;
  final String targetSound;
  final bool correctAnswer;
  final String yesLabel;
  final String noLabel;

  const SoundPresenceQuestion({
    required this.prompt,
    required this.promptAudioUrl,
    required this.wordText,
    required this.wordAudioUrl,
    required this.targetSound,
    required this.correctAnswer,
    required this.yesLabel,
    required this.noLabel,
  });

  factory SoundPresenceQuestion.fromMap(Map<String, dynamic> map) {
    return SoundPresenceQuestion(
      prompt: map['prompt'] as String? ?? '',
      promptAudioUrl: map['prompt_audio_url'] as String? ?? '',
      wordText: map['word_text'] as String? ?? '',
      wordAudioUrl: map['word_audio_url'] as String? ?? '',
      targetSound: map['target_sound'] as String? ?? '',
      correctAnswer: map['correct_answer'] as bool? ?? false,
      yesLabel: map['yes_label'] as String? ?? 'Yes',
      noLabel: map['no_label'] as String? ?? 'No',
    );
  }

  String get displayTargetSound => '/$targetSound/';
}
