import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import 'package:milpress/providers/audio_service_provider.dart';

class AudioPlayButton extends ConsumerStatefulWidget {
  final String screenId; // New: screen identifier for session management
  final String lottieAsset;
  final String audioStoragePath;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final bool showReplayButton;
  final bool showClearCacheButton;

  const AudioPlayButton({
    Key? key,
    required this.screenId,
    required this.lottieAsset,
    required this.audioStoragePath,
    this.backgroundColor = Colors.orange,
    this.height = 32,
    this.borderRadius = 26,
    this.showReplayButton = false,
    this.showClearCacheButton = false,
  }) : super(key: key);

  @override
  ConsumerState<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends ConsumerState<AudioPlayButton> {
  @override
  void initState() {
    super.initState();
    // Register this screen's audio with the session provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerScreenAudio();
    });
  }

  Future<void> _registerScreenAudio() async {
    try {
      // Check if audio is already prefetched in splash screen
      final dir = await getTemporaryDirectory();
      final fileName = widget.audioStoragePath.split('/').last;
      final localFilePath = '${dir.path}/$fileName';
      final file = File(localFilePath);
      
      if (await file.exists()) {
        // Use the prefetched file directly
        await ref.read(audioSessionProvider.notifier).registerScreenAudio(
          screenId: widget.screenId,
          audioPath: localFilePath,
        );
        print('AudioPlayButton: Using prefetched audio file: $localFilePath');
      } else {
        // Fallback to original storage path if not prefetched
        await ref.read(audioSessionProvider.notifier).registerScreenAudio(
          screenId: widget.screenId,
          audioPath: widget.audioStoragePath,
        );
        print('AudioPlayButton: Using storage path: ${widget.audioStoragePath}');
      }
    } catch (e) {
      print('AudioPlayButton: Failed to register screen audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the audio session state for this screen
    final sessionState = ref.watch(audioSessionProvider);
    final audioState = ref.watch(audioSessionProvider.notifier).getScreenAudioState(widget.screenId);

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.showClearCacheButton ? _showClearCacheDialog : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 25),
        decoration: BoxDecoration(
          color: audioState.isPlaying ? widget.backgroundColor : AppColors.sandColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show Lottie animation ONLY when audio is actively playing
            if (audioState.isPlaying && !audioState.isLoading)
              Lottie.asset(
                widget.lottieAsset,
                height: widget.height,
                repeat: true,
                onLoaded: (composition) {
                  print('AudioPlayButton: Lottie loaded successfully - duration: ${composition.duration}');
                },
                errorBuilder: (context, error, stackTrace) {
                  print('AudioPlayButton: Lottie error for asset ${widget.lottieAsset}: $error');
                  print('AudioPlayButton: Falling back to static speaker icon');
                  return SvgPicture.asset(
                    'assets/speaker_icon.svg',
                    height: widget.height,
                    color: AppColors.primaryColor,
                  );
                },
              )
            else
              SvgPicture.asset(
                'assets/speaker_icon.svg',
                height: widget.height,
                color: AppColors.primaryColor,
              ),
            const SizedBox(width: 12),
            Icon(
              audioState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 26,
              color: audioState.isPlaying ? Colors.white : AppColors.primaryColor,
            ),
            if (audioState.isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            if (widget.showReplayButton && audioState.isCached && !audioState.isPlaying)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: GestureDetector(
                  onTap: _handleReplay,
                  child: const Icon(
                    Icons.replay,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap() async {
    // Get current audio state for this screen
    final audioState = ref.read(audioSessionProvider.notifier).getScreenAudioState(widget.screenId);
    
    if (audioState.isLoading) return; // Don't allow interaction while loading

    try {
      if (audioState.isPlaying) {
        // If playing, pause it
        await ref.read(audioSessionProvider.notifier).pauseAudio(widget.screenId);
      } else {
        // If not playing, start session and play
        await ref.read(audioSessionProvider.notifier).startSession(widget.screenId);
      }
    } catch (e) {
      _showErrorSnackBar('Audio operation failed: $e');
    }
  }

  void _handleReplay() async {
    try {
      await ref.read(audioSessionProvider.notifier).replayAudio(widget.screenId);
    } catch (e) {
      _showErrorSnackBar('Failed to replay audio: $e');
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Audio Cache'),
          content: const Text('This will remove all cached audio files. Audio files will need to be downloaded again when played.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearCache();
              },
              child: const Text('Clear Cache'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    try {
      // Stop current session first
      await ref.read(audioSessionProvider.notifier).stopSession(widget.screenId);
      
      // Clear all cache
      await ref.read(audioServiceProvider.notifier).clearCache();
      _showSuccessSnackBar('Audio cache cleared successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to clear cache: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
