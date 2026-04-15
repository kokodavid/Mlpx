class BlendingConfig {
  final String title;
  final String instruction;
  final String instructionAudioUrl;
  final List<BlendingExample> examples;

  const BlendingConfig({
    required this.title,
    required this.instruction,
    required this.instructionAudioUrl,
    required this.examples,
  });

  factory BlendingConfig.fromMap(Map<String, dynamic> map) {
    final examples = (map['examples'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BlendingExample.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);

    return BlendingConfig(
      title: map['title'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      examples: examples.isEmpty
          ? const [
              BlendingExample(
                word: '',
                wordAudioUrl: '',
                phonemes: [],
              ),
            ]
          : examples,
    );
  }
}

class BlendingExample {
  final String word;
  final String wordAudioUrl;
  final List<BlendingPhoneme> phonemes;

  const BlendingExample({
    required this.word,
    required this.wordAudioUrl,
    required this.phonemes,
  });

  factory BlendingExample.fromMap(Map<String, dynamic> map) {
    final phonemes = (map['phonemes'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BlendingPhoneme.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);

    return BlendingExample(
      word: map['word'] as String? ?? '',
      wordAudioUrl: map['word_audio_url'] as String? ?? '',
      phonemes: phonemes,
    );
  }
}

class BlendingPhoneme {
  final String label;
  final String audioUrl;
  final bool highlighted;

  const BlendingPhoneme({
    required this.label,
    required this.audioUrl,
    required this.highlighted,
  });

  factory BlendingPhoneme.fromMap(Map<String, dynamic> map) {
    return BlendingPhoneme(
      label: map['label'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      highlighted: map['highlighted'] as bool? ?? false,
    );
  }
}