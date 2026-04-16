class WordReadingConfig {
  final String title;
  final String instructionAudioUrl;
  final List<WordReadingItem> items;

  const WordReadingConfig({
    required this.title,
    required this.instructionAudioUrl,
    required this.items,
  });

  factory WordReadingConfig.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => WordReadingItem.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);

    return WordReadingConfig(
      title: map['title'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      items: items.isEmpty
          ? const [
              WordReadingItem(
                word: '',
                imageUrl: '',
                wordAudioUrl: '',
                modelReadingLabel: '',
                segments: [],
              ),
            ]
          : items,
    );
  }
}

class WordReadingItem {
  final String word;
  final String imageUrl;
  final String wordAudioUrl;
  final String modelReadingLabel;
  final List<WordSegment> segments;

  const WordReadingItem({
    required this.word,
    required this.imageUrl,
    required this.wordAudioUrl,
    required this.modelReadingLabel,
    required this.segments,
  });

  factory WordReadingItem.fromMap(Map<String, dynamic> map) {
    final segments = (map['segments'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((s) => WordSegment.fromMap(s.cast<String, dynamic>()))
        .toList(growable: false);

    return WordReadingItem(
      word: map['word'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      wordAudioUrl: map['word_audio_url'] as String? ?? '',
      modelReadingLabel: map['model_reading_label'] as String? ?? '',
      segments: segments,
    );
  }
}

class WordSegment {
  final String label;
  final String audioUrl;
  final bool highlighted;

  const WordSegment({
    required this.label,
    required this.audioUrl,
    required this.highlighted,
  });

  factory WordSegment.fromMap(Map<String, dynamic> map) {
    return WordSegment(
      label: map['label'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      highlighted: map['highlighted'] as bool? ?? false,
    );
  }
}