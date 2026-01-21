import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum LessonAudioStatus {
  idle,
  loading,
  playing,
  error,
}

class LessonAudioState {
  final LessonAudioStatus status;
  final String? sourceId;
  final String? errorMessage;

  const LessonAudioState({
    this.status = LessonAudioStatus.idle,
    this.sourceId,
    this.errorMessage,
  });

  LessonAudioState copyWith({
    LessonAudioStatus? status,
    String? sourceId,
    String? errorMessage,
  }) {
    return LessonAudioState(
      status: status ?? this.status,
      sourceId: sourceId ?? this.sourceId,
      errorMessage: errorMessage,
    );
  }
}

class LessonAudioController {
  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<LessonAudioState> state =
      ValueNotifier<LessonAudioState>(const LessonAudioState());
  String? _currentUrl;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  String? _activeSourceId;

  LessonAudioController() {
    _processingStateSub =
        _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        stop();
      }
    });
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        state.value = state.value.copyWith(
          status: LessonAudioStatus.loading,
          sourceId: _activeSourceId,
        );
        return;
      }

      if (playerState.playing) {
        state.value = state.value.copyWith(
          status: LessonAudioStatus.playing,
          sourceId: _activeSourceId,
        );
        return;
      }

      if (playerState.processingState == ProcessingState.completed) {
        _activeSourceId = null;
        _currentUrl = null;
        state.value = state.value.copyWith(
          status: LessonAudioStatus.idle,
          sourceId: null,
        );
        return;
      }

      state.value = state.value.copyWith(
        status: LessonAudioStatus.idle,
        sourceId: _activeSourceId,
      );
    });
  }

  Future<void> playUrl(String url, {required String sourceId}) async {
    if (url.isEmpty) {
      debugPrint(
          'LessonAudioController: empty url for sourceId=$sourceId, skipping');
      return;
    }
    _currentUrl = url;
    _activeSourceId = sourceId;
    state.value = state.value.copyWith(
      status: LessonAudioStatus.loading,
      sourceId: sourceId,
      errorMessage: null,
    );
    debugPrint(
        'LessonAudioController: loading url for sourceId=$sourceId url=$url');
    try {
      if (_currentUrl != null) {
        await _player.stop();
      }
      _currentUrl = url;
      await _player.setUrl(url);
      await _player.setVolume(1.0);
      await _player.play();
      debugPrint('LessonAudioController: play requested sourceId=$sourceId');
    } catch (e) {
      _activeSourceId = null;
      state.value = state.value.copyWith(
        status: LessonAudioStatus.error,
        errorMessage: e.toString(),
        sourceId: sourceId,
      );
      debugPrint(
          'LessonAudioController: error sourceId=$sourceId error=$e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
    _activeSourceId = null;
    state.value =
        state.value.copyWith(status: LessonAudioStatus.idle, sourceId: null);
    debugPrint('LessonAudioController: stopped');
  }

  void dispose() {
    _playerStateSub?.cancel();
    _processingStateSub?.cancel();
    state.dispose();
    _player.dispose();
  }
}
