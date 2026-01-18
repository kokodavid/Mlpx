import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lesson_audio_controller.dart';

final lessonAudioControllerProvider = Provider<LessonAudioController>((ref) {
  final controller = LessonAudioController();
  ref.onDispose(controller.dispose);
  return controller;
});
