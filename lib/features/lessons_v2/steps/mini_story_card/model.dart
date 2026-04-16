class MiniStoryCardConfig {
  final String title;
  final String? instructionAudioUrl;
  final List<MiniStoryCardItem> items;

  const MiniStoryCardConfig({
    required this.title,
    this.instructionAudioUrl,
    required this.items,
  });

  factory MiniStoryCardConfig.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => MiniStoryCardItem.fromMap(e.cast<String, dynamic>()))
        .toList(growable: false);

    return MiniStoryCardConfig(
      title: map['title'] as String? ?? 'Read the story',
      instructionAudioUrl: map['instruction_audio_url'] as String?,
      items: items.isEmpty
          ? const [
              MiniStoryCardItem(
                heading: '',
                bodyLines: [''],
                storyAudioUrl: '',
              ),
            ]
          : items,
    );
  }
}

class MiniStoryCardItem {
  final String heading;
  final String? headingAudioUrl;
  final List<String> bodyLines;
  final String storyAudioUrl;
  final String? ctaLabel;

  const MiniStoryCardItem({
    required this.heading,
    this.headingAudioUrl,
    required this.bodyLines,
    required this.storyAudioUrl,
    this.ctaLabel,
  });

  factory MiniStoryCardItem.fromMap(Map<String, dynamic> map) {
    final lines = (map['body_lines'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    return MiniStoryCardItem(
      heading: map['heading'] as String? ?? '',
      headingAudioUrl: map['heading_audio_url'] as String?,
      bodyLines: lines.isEmpty ? const [''] : lines,
      storyAudioUrl: map['story_audio_url'] as String? ?? '',
      ctaLabel: map['cta_label'] as String?,
    );
  }

  /// Full story body as a single string for display.
  String get bodyText => bodyLines.join('\n');
}