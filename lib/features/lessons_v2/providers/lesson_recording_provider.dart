import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/lesson_recording_controller.dart';

enum LessonRecordingPhase {
  idle,
  recording,
  readyToPlay,
  playing,
}

class LessonRecordingState {
  final LessonRecordingPhase phase;
  final String? errorMessage;
  final bool hasCompletedCycle;

  const LessonRecordingState({
    this.phase = LessonRecordingPhase.idle,
    this.errorMessage,
    this.hasCompletedCycle = false,
  });

  bool get isRecording => phase == LessonRecordingPhase.recording;
  bool get isReadyToPlay => phase == LessonRecordingPhase.readyToPlay;
  bool get isPlaying => phase == LessonRecordingPhase.playing;

  String get statusText {
    switch (phase) {
      case LessonRecordingPhase.recording:
        return 'Recording...';
      case LessonRecordingPhase.readyToPlay:
        return 'Tap to play your recording.';
      case LessonRecordingPhase.playing:
        return 'Playing...';
      case LessonRecordingPhase.idle:
        return 'Tap to start recording.\nYour turn - say it out loud';
    }
  }

  LessonRecordingState copyWith({
    LessonRecordingPhase? phase,
    String? errorMessage,
    bool? hasCompletedCycle,
    bool clearErrorMessage = false,
  }) {
    return LessonRecordingState(
      phase: phase ?? this.phase,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      hasCompletedCycle: hasCompletedCycle ?? this.hasCompletedCycle,
    );
  }
}

final lessonRecordingProvider = StateNotifierProvider.autoDispose
    .family<LessonRecordingNotifier, LessonRecordingState, String>(
  (ref, sourceId) => LessonRecordingNotifier(),
);

class LessonRecordingNotifier extends StateNotifier<LessonRecordingState> {
  static const _recordingDuration = Duration(seconds: 4);

  final LessonRecordingController _controller;
  AudioPlayer _player;
  final List<int> _pcmBytes = [];

  StreamSubscription<Uint8List>? _recordingSubscription;
  Timer? _recordingTimer;
  Uint8List? _recordingBytes;

  LessonRecordingNotifier()
      : _controller = LessonRecordingController(),
        _player = AudioPlayer(),
        super(const LessonRecordingState());

  Future<void> handleButtonPress() async {
    if (state.isRecording || state.isPlaying) {
      return;
    }

    if (state.isReadyToPlay) {
      await playRecording();
      return;
    }

    await startRecording();
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _controller.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          phase: LessonRecordingPhase.idle,
          errorMessage: 'Microphone permission is required.',
        );
        return;
      }

      _clearRecording();
      _pcmBytes.clear();

      final stream = await _controller.startRecording();
      _recordingSubscription = stream.listen(_pcmBytes.addAll);
      _recordingTimer = Timer(
        _recordingDuration,
        () => unawaited(stopRecording()),
      );

      state = state.copyWith(
        phase: LessonRecordingPhase.recording,
        clearErrorMessage: true,
      );
    } catch (error) {
      _clearRecording();
      state = state.copyWith(
        phase: LessonRecordingPhase.idle,
        errorMessage: 'Could not start recording.',
      );
    }
  }

  Future<void> stopRecording() async {
    if (!state.isRecording) {
      return;
    }

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      await _controller.stopRecording();
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;

      if (_pcmBytes.isEmpty) {
        state = state.copyWith(
          phase: LessonRecordingPhase.idle,
          errorMessage: 'No audio was captured. Try again.',
        );
        return;
      }

      _recordingBytes = _buildWavBytes(
        pcmBytes: _pcmBytes,
        sampleRate: LessonRecordingController.sampleRate,
        channels: LessonRecordingController.numChannels,
      );

      state = state.copyWith(
        phase: LessonRecordingPhase.readyToPlay,
        clearErrorMessage: true,
      );
    } catch (error) {
      _clearRecording();
      state = state.copyWith(
        phase: LessonRecordingPhase.idle,
        errorMessage: 'Could not stop recording.',
      );
    }
  }

  Future<void> playRecording() async {
    final bytes = _recordingBytes;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(phase: LessonRecordingPhase.idle);
      return;
    }

    try {
      state = state.copyWith(
        phase: LessonRecordingPhase.playing,
        clearErrorMessage: true,
      );

      await _player.stop();
      await _player.setAudioSource(_MemoryAudioSource(bytes));
      final playbackComplete = _player.playerStateStream.firstWhere(
        (playerState) =>
            playerState.processingState == ProcessingState.completed,
      );
      await _player.play();
      await playbackComplete;
    } catch (error) {
      state = state.copyWith(
        phase: LessonRecordingPhase.readyToPlay,
        errorMessage: 'Could not play recording.',
      );
      return;
    }

    await _player.stop();
    await _player.dispose();
    _player = AudioPlayer();
    _clearRecording();
    state = state.copyWith(
      phase: LessonRecordingPhase.idle,
      hasCompletedCycle: true,
      clearErrorMessage: true,
    );
  }

  void _clearRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final subscription = _recordingSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _recordingSubscription = null;
    _recordingBytes = null;
    _pcmBytes.clear();
  }

  @override
  void dispose() {
    if (state.isRecording) {
      unawaited(_controller.stopRecording());
    }
    _clearRecording();
    unawaited(_controller.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }
}

class _MemoryAudioSource extends StreamAudioSource {
  final Uint8List bytes;

  _MemoryAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final effectiveStart = (start ?? 0).clamp(0, bytes.length) as int;
    final effectiveEnd = (end ?? bytes.length).clamp(
      effectiveStart,
      bytes.length,
    ) as int;
    final rangeBytes = bytes.sublist(effectiveStart, effectiveEnd);

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: rangeBytes.length,
      offset: effectiveStart,
      contentType: 'audio/wav',
      stream: Stream.value(rangeBytes),
    );
  }
}

Uint8List _buildWavBytes({
  required List<int> pcmBytes,
  required int sampleRate,
  required int channels,
}) {
  const bitsPerSample = 16;
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataLength = pcmBytes.length;
  final fileLength = 36 + dataLength;
  final bytes = BytesBuilder();

  bytes.add(_ascii('RIFF'));
  bytes.add(_uint32(fileLength));
  bytes.add(_ascii('WAVE'));
  bytes.add(_ascii('fmt '));
  bytes.add(_uint32(16));
  bytes.add(_uint16(1));
  bytes.add(_uint16(channels));
  bytes.add(_uint32(sampleRate));
  bytes.add(_uint32(byteRate));
  bytes.add(_uint16(blockAlign));
  bytes.add(_uint16(bitsPerSample));
  bytes.add(_ascii('data'));
  bytes.add(_uint32(dataLength));
  bytes.add(pcmBytes);

  return bytes.toBytes();
}

Uint8List _ascii(String value) {
  return Uint8List.fromList(value.codeUnits);
}

Uint8List _uint16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _uint32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}
