import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import 'package:milpress/providers/audio_cache_provider.dart';

class ListenSection extends ConsumerStatefulWidget {
  final String soundFileUrl;
  final double iconSize;
  final String screenId; // Add screen ID for session management

  const ListenSection({
    Key? key,
    required this.soundFileUrl,
    this.iconSize = 24.0,
    required this.screenId,
  }) : super(key: key);

  @override
  ConsumerState<ListenSection> createState() => _ListenSectionState();
}

class _ListenSectionState extends ConsumerState<ListenSection> {
  @override
  void initState() {
    super.initState();
    // Register this audio with the session provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAudio();
    });
  }

  @override
  void didUpdateWidget(ListenSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Re-register audio if the soundFileUrl or screenId changed
    if (oldWidget.soundFileUrl != widget.soundFileUrl || 
        oldWidget.screenId != widget.screenId) {
      print('ListenSection: Widget updated - re-registering audio');
      print('ListenSection: Old URL: ${oldWidget.soundFileUrl} -> New URL: ${widget.soundFileUrl}');
      print('ListenSection: Old screenId: ${oldWidget.screenId} -> New screenId: ${widget.screenId}');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerAudio();
      });
    }
  }

  Future<void> _registerAudio() async {
    try {
      print('ListenSection: Registering audio for screen ${widget.screenId}');
      print('ListenSection: Audio path: ${widget.soundFileUrl}');
      
      // Check if audio is already cached
      final cacheState = ref.read(audioCacheProvider);
      final isCached = cacheState.isCached(widget.soundFileUrl);
      print('ListenSection: Audio cached: $isCached');
      
      if (isCached) {
        final cachedPath = cacheState.getCachedPath(widget.soundFileUrl);
        print('ListenSection: Cached file path: $cachedPath');
      }
      
      await ref.read(audioSessionProvider.notifier).registerScreenAudio(
        screenId: widget.screenId,
        audioPath: widget.soundFileUrl,
      );
      print('ListenSection: Successfully registered audio for screen ${widget.screenId}: ${widget.soundFileUrl}');
    } catch (e) {
      print('ListenSection: Failed to register audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the audio session state for this screen
    final audioState = ref.watch(audioSessionProvider.notifier).getScreenAudioState(widget.screenId);

    return GestureDetector(
      onTap: audioState.isLoading ? null : _handleTap,
      child: Row(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.sandColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(10.0),
              child: audioState.isLoading
                  ? SizedBox(
                      width: widget.iconSize,
                      height: widget.iconSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/speaker_icon.svg',
                      color: audioState.isPlaying ? AppColors.primaryColor : null,
                      width: widget.iconSize,
                      height: widget.iconSize,
                    ),
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            audioState.isPlaying ? 'Click to pause' : 'Click to listen',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16.0,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap() async {
    try {
      print('ListenSection: Tap detected for screen ${widget.screenId}');
      print('ListenSection: Audio URL: ${widget.soundFileUrl}');
      
      // Get current audio state for this screen
      final audioState = ref.read(audioSessionProvider.notifier).getScreenAudioState(widget.screenId);
      print('ListenSection: Current audio state - isPlaying: ${audioState.isPlaying}, isLoading: ${audioState.isLoading}, isCached: ${audioState.isCached}');
      
      // Check if audio is cached
      final cacheState = ref.read(audioCacheProvider);
      final isCached = cacheState.isCached(widget.soundFileUrl);
      print('ListenSection: Audio cached in provider: $isCached');
      
      if (audioState.isPlaying) {
        print('ListenSection: Pausing audio...');
        // If playing, pause it
        await ref.read(audioSessionProvider.notifier).pauseAudio(widget.screenId);
      } else {
        print('ListenSection: Starting session and playing audio...');
        // If not playing, start session and play
        await ref.read(audioSessionProvider.notifier).startSession(widget.screenId);
      }
    } catch (e) {
      print('ListenSection: Audio operation failed: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio playback failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}