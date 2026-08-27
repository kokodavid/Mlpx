class SentenceReadingConfig {
  final String title;
  final String instructionAudioUrl;
  final List<SentenceReadingItem> items;

  const SentenceReadingConfig({
    required this.title,
    required this.instructionAudioUrl,
    required this.items,
  });

  factory SentenceReadingConfig.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) =>
            SentenceReadingItem.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);

    return SentenceReadingConfig(
      title: map['title'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      items: items.isEmpty
          ? const [
              SentenceReadingItem(
                sentenceText: '',
                displayTokens: [],
                sentenceAudioUrl: '',
                selfReadLabel: '',
              ),
            ]
          : items,
    );
  }
}

class SentenceReadingItem {
  final String sentenceText;
  final List<String> displayTokens;
  final String sentenceAudioUrl;
  final String selfReadLabel;

  const SentenceReadingItem({
    required this.sentenceText,
    required this.displayTokens,
    required this.sentenceAudioUrl,
    required this.selfReadLabel,
  });

  factory SentenceReadingItem.fromMap(Map<String, dynamic> map) {
    final tokens = (map['display_tokens'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    return SentenceReadingItem(
      sentenceText: map['sentence_text'] as String? ?? '',
      displayTokens: tokens,
      sentenceAudioUrl: map['sentence_audio_url'] as String? ?? '',
      selfReadLabel: map['self_read_label'] as String? ?? '',
    );
  }
}