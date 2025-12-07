import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

final lessonVideoPlayerControllerProvider = AutoDisposeFutureProvider.family<VideoPlayerController, String>((ref, videoUrl) async {
  final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
  await controller.initialize();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
}); 

final lessonVideoPlaybackProvider = StateProvider.autoDispose<bool>((ref) => false); // false = paused, true = playing 