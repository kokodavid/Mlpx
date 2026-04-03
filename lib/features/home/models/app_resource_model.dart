class AppResource {
  final String id;
  final String label;
  final String fileUrl;
  final String audioUrl;
  final String type; // 'pdf' | 'video'
  final int displayOrder;

  const AppResource({
    required this.id,
    required this.label,
    required this.fileUrl,
    required this.audioUrl,
    required this.type,
    required this.displayOrder,
  });

  factory AppResource.fromMap(Map<String, dynamic> map) => AppResource(
        id: map['id'] as String,
        label: map['label'] as String,
        fileUrl: map['file_url'] as String? ?? '',
        audioUrl: map['audio_url'] as String? ?? '',
        type: map['type'] as String? ?? 'pdf',
        displayOrder: map['display_order'] as int? ?? 0,
      );
}
