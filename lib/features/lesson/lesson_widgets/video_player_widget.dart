import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final double height;
  final double borderRadius;
  final VideoPlayerController? externalController;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.height = 200,
    this.borderRadius = 16,
    this.externalController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _VideoPlayerDisplay(
      videoUrl: videoUrl,
      height: height,
      borderRadius: borderRadius,
      externalController: externalController,
    );
  }
}

class _VideoPlayerDisplay extends StatefulWidget {
  final String videoUrl;
  final double height;
  final double borderRadius;
  final VideoPlayerController? externalController;

  const _VideoPlayerDisplay({
    Key? key,
    required this.videoUrl,
    required this.height,
    required this.borderRadius,
    this.externalController,
  }) : super(key: key);

  @override
  State<_VideoPlayerDisplay> createState() => _VideoPlayerDisplayState();
}

class _VideoPlayerDisplayState extends State<_VideoPlayerDisplay> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isExternal = false;

  @override
  void initState() {
    super.initState();
    if (widget.externalController != null) {
      _controller = widget.externalController;
      _isExternal = true;
      if (_controller!.value.isInitialized) {
        _initialized = true;
      } else {
        _controller!.initialize().then((_) {
          setState(() {
            _initialized = true;
          });
        });
      }
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {
            _initialized = true;
          });
        });
    }
  }

  @override
  void dispose() {
    if (!_isExternal) {
      _controller?.dispose();
    }
    super.dispose();
  }

  void _openFullscreen() {
    if (_controller == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenVideoPlayer(controller: _controller!),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        color: Colors.black,
        height: widget.height,
        width: double.infinity,
        child: _initialized && _controller != null
            ? Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _openFullscreen,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenVideoPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  VideoPlayerController get controller => widget.controller;

  void _togglePlayPause() {
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _seekRelative(Duration offset) {
    final newPosition = controller.value.position + offset;
    final duration = controller.value.duration;
    controller.seekTo(
      newPosition < Duration.zero
          ? Duration.zero
          : (newPosition > duration ? duration : newPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            // Video controls (only in fullscreen)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                        onPressed: () => _seekRelative(const Duration(seconds: -10)),
                      ),
                      IconButton(
                        icon: Icon(
                          controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                        onPressed: () => _seekRelative(const Duration(seconds: 10)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.orange,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 24,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 