import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/home/providers/app_content_provider.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import 'package:milpress/features/lesson/lesson_widgets/video_player_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeIntroTile extends ConsumerWidget {
  final EdgeInsetsGeometry margin;

  const HomeIntroTile({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
  });

  void _openVideoDialog(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'What is Milpress',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              VideoPlayerWidget(
                videoUrl: videoUrl,
                height: 200,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadResource(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(appContentProvider);
    final resourcesAsync = ref.watch(appResourcesProvider);

    final introVideoUrl = contentAsync.valueOrNull?.introVideoUrl ?? '';
    final thumbnailUrl = contentAsync.valueOrNull?.introVideoThumbnailUrl ?? '';

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const Center(
            child: Text(
              'Welcome to Milpress educational',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10131A),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Chapter 1
          const _ChapterHeader(number: 1, title: 'What is Milpress'),
          const SizedBox(height: 10),
          _VideoThumbnail(
            thumbnailUrl: thumbnailUrl,
            onTap: introVideoUrl.isEmpty
                ? null
                : () => _openVideoDialog(context, introVideoUrl),
          ),
          const SizedBox(height: 18),

          // Chapter 2
          const _ChapterHeader(number: 2, title: 'Milpress Resources'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: resourcesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (resources) {
                if (resources.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    for (int i = 0; i < resources.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: AppColors.borderColor.withValues(alpha: 0.6),
                          indent: 16,
                          endIndent: 16,
                        ),
                      _ResourceRow(
                        resourceId: resources[i].id,
                        label: resources[i].label,
                        audioUrl: resources[i].audioUrl,
                        onDownload: resources[i].fileUrl.isEmpty
                            ? null
                            : () => _downloadResource(resources[i].fileUrl),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    ),
  ),
);
  }
}

class _ChapterHeader extends StatelessWidget {
  final int number;
  final String title;

  const _ChapterHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderColor),
            color: const Color(0xFFF2F2F2),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C6C6C),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF10131A),
          ),
        ),
      ],
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final VoidCallback? onTap;
  final String thumbnailUrl;

  const _VideoThumbnail({this.onTap, this.thumbnailUrl = ''});

  @override
  Widget build(BuildContext context) {
    final hasThumb = thumbnailUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
          image: hasThumb
              ? DecorationImage(
                  image: CachedNetworkImageProvider(thumbnailUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Center(
          child: CircleAvatar(
            radius: 26,
            backgroundColor: onTap != null
                ? AppColors.copBlue
                : const Color(0xFF10131A).withValues(alpha: 0.3),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceRow extends ConsumerStatefulWidget {
  final String resourceId;
  final String label;
  final String audioUrl;
  final VoidCallback? onDownload;

  const _ResourceRow({
    required this.resourceId,
    required this.label,
    required this.audioUrl,
    this.onDownload,
  });

  @override
  ConsumerState<_ResourceRow> createState() => _ResourceRowState();
}

class _ResourceRowState extends ConsumerState<_ResourceRow> {
  String get _screenId => 'resource_${widget.resourceId}';

  @override
  void initState() {
    super.initState();
    if (widget.audioUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audioSessionProvider.notifier).registerScreenAudio(
              screenId: _screenId,
              audioPath: widget.audioUrl,
            );
      });
    }
  }

  Future<void> _handleAudioTap() async {
    final audioState =
        ref.read(audioSessionProvider.notifier).getScreenAudioState(_screenId);
    if (audioState.isLoading) return;
    if (audioState.isPlaying) {
      await ref.read(audioSessionProvider.notifier).pauseAudio(_screenId);
    } else {
      await ref.read(audioSessionProvider.notifier).startSession(_screenId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioSessionProvider.notifier).getScreenAudioState(_screenId);
    final hasAudio = widget.audioUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasAudio ? _handleAudioTap : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasAudio
                    ? const Color(0xFF1A2340)
                    : const Color(0xFF1A2340).withValues(alpha: 0.4),
              ),
              child: audioState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      audioState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.greyText,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onDownload,
            child: Icon(
              Icons.download_outlined,
              color: widget.onDownload != null
                  ? const Color(0xFF6C6C6C)
                  : const Color(0xFF6C6C6C).withValues(alpha: 0.4),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
