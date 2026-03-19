class AppContent {
  final String? introVideoUrl;
  final String? introVideoThumbnailUrl;
  final String? helpVideoUrl;

  const AppContent({
    this.introVideoUrl,
    this.introVideoThumbnailUrl,
    this.helpVideoUrl,
  });

  factory AppContent.fromMap(Map<String, dynamic> map) => AppContent(
        introVideoUrl: map['intro_video_url'] as String?,
        introVideoThumbnailUrl: map['intro_video_thumbnail_url'] as String?,
        helpVideoUrl: map['help_video_url'] as String?,
      );
}
