class GuidedReadingConfig {
  final String title;
  final List<GuidedReadingActivity> activities;

  const GuidedReadingConfig({
    required this.title,
    required this.activities,
  });

  factory GuidedReadingConfig.fromMap(Map<String, dynamic> map) {
    final activities = (map['activities'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((activity) =>
            GuidedReadingActivity.fromMap(activity.cast<String, dynamic>()))
        .toList(growable: false);

    return GuidedReadingConfig(
      title: map['title'] as String? ?? '',
      activities: activities.isEmpty
          ? const [
              GuidedReadingActivity(
                instructionText: '',
                instructionAudioUrl: '',
                wordText: '',
                wordAudioUrl: '',
                segments: [
                  GuidedReadingSegment(
                    phonemeLabel: '',
                    grapheme: '',
                    audioUrl: '',
                    isFocus: false,
                  ),
                ],
              ),
            ]
          : activities,
    );
  }
}

class GuidedReadingActivity {
  final String instructionText;
  final String instructionAudioUrl;
  final String wordText;
  final String wordAudioUrl;
  final List<GuidedReadingSegment> segments;

  const GuidedReadingActivity({
    required this.instructionText,
    required this.instructionAudioUrl,
    required this.wordText,
    required this.wordAudioUrl,
    required this.segments,
  });

  factory GuidedReadingActivity.fromMap(Map<String, dynamic> map) {
    final segments = (map['segments'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((segment) =>
            GuidedReadingSegment.fromMap(segment.cast<String, dynamic>()))
        .toList(growable: false);

    return GuidedReadingActivity(
      instructionText: map['instruction_text'] as String? ?? '',
      instructionAudioUrl: map['instruction_audio_url'] as String? ?? '',
      wordText: map['word_text'] as String? ?? '',
      wordAudioUrl: map['word_audio_url'] as String? ?? '',
      segments: segments.isEmpty
          ? const [
              GuidedReadingSegment(
                phonemeLabel: '',
                grapheme: '',
                audioUrl: '',
                isFocus: false,
              ),
            ]
          : segments,
    );
  }
}

class GuidedReadingSegment {
  final String phonemeLabel;
  final String grapheme;
  final String audioUrl;
  final bool isFocus;

  const GuidedReadingSegment({
    required this.phonemeLabel,
    required this.grapheme,
    required this.audioUrl,
    required this.isFocus,
  });

  factory GuidedReadingSegment.fromMap(Map<String, dynamic> map) {
    return GuidedReadingSegment(
      phonemeLabel: map['phoneme_label'] as String? ?? '',
      grapheme: map['grapheme'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      isFocus: map['is_focus'] as bool? ?? false,
    );
  }
}
