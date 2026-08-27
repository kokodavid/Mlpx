class SoundDiscriminationConfig {
  final String title;
  final String titleAudioUrl;
  final String targetSound;
  final String referenceWord;
  final String tipText;
  final String instructionText;
  final List<SoundDiscriminationItem> items;

  const SoundDiscriminationConfig({
    required this.title,
    required this.titleAudioUrl,
    required this.targetSound,
    required this.referenceWord,
    required this.tipText,
    required this.instructionText,
    required this.items,
  });

  factory SoundDiscriminationConfig.fromMap(Map<String, dynamic> config) {
    final items = (config['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => SoundDiscriminationItem.fromMap(
              item.cast<String, dynamic>(),
            ))
        .toList(growable: false);

    return SoundDiscriminationConfig(
      title: config['title'] as String? ?? '',
      titleAudioUrl: config['title_audio_url'] as String? ?? '',
      targetSound: config['target_sound'] as String? ?? '',
      referenceWord: config['reference_word'] as String? ?? '',
      tipText: config['tip_text'] as String? ?? '',
      instructionText: config['instruction_text'] as String? ?? '',
      items: items.isEmpty
          ? const [
              SoundDiscriminationItem(
                title: '',
                titleAudioUrl: '',
                imageUrl: '',
                containsTargetSound: false,
                highlightedText: '',
              ),
            ]
          : items,
    );
  }

  String get displayTargetSound {
    final normalized = targetSound.replaceAll(RegExp(r'^/+|/+$'), '');
    return '/$normalized/';
  }
}

class SoundDiscriminationItem {
  final String title;
  final String titleAudioUrl;
  final String imageUrl;
  final bool containsTargetSound;
  final String highlightedText;

  const SoundDiscriminationItem({
    required this.title,
    required this.titleAudioUrl,
    required this.imageUrl,
    required this.containsTargetSound,
    required this.highlightedText,
  });

  factory SoundDiscriminationItem.fromMap(Map<String, dynamic> map) {
    return SoundDiscriminationItem(
      title: map['title'] as String? ?? '',
      titleAudioUrl: map['title_audio_url'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      containsTargetSound: map['contains_target_sound'] as bool? ?? false,
      highlightedText: map['highlighted_text'] as String? ?? '',
    );
  }
}