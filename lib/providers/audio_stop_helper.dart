import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_audio_providers.dart';
import 'package:milpress/providers/audio_session_provider.dart';

void stopAllAudio(WidgetRef ref) {
  unawaited(ref.read(audioSessionProvider.notifier).stopActiveSession());
  unawaited(ref.read(lessonAudioControllerProvider).stop());
}
