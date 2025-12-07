import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// Audio Player State
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final String? currentAudioPath;
  final Duration position;
  final Duration duration;
  final String? error;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentAudioPath,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    String? currentAudioPath,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentAudioPath: currentAudioPath ?? this.currentAudioPath,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}

// Audio Player Notifier
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final isActuallyPlaying = playerState.playing && 
          playerState.processingState == ProcessingState.ready;
      
      state = state.copyWith(
        isPlaying: isActuallyPlaying,
        isLoading: playerState.processingState == ProcessingState.loading ||
                  playerState.processingState == ProcessingState.buffering,
      );
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // Listen to completion
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          isLoading: false,
        );
      }
    });
  }

  // Play audio from file path
  Future<void> playAudio(String audioPath) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentAudioPath: audioPath,
      );

      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play audio: $e',
        isPlaying: false,
      );
    }
  }

  // Pause audio
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause audio: $e');
    }
  }

  // Resume audio
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume audio: $e');
    }
  }

  // Stop audio
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        currentAudioPath: null,
        position: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop audio: $e');
    }
  }

  // Replay audio (stop and play from beginning)
  Future<void> replayAudio() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(error: 'Failed to replay audio: $e');
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      state = state.copyWith(error: 'Failed to seek audio: $e');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Check if specific audio is currently playing
  bool isAudioPlaying(String audioPath) {
    return state.isPlaying && state.currentAudioPath == audioPath;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Provider
final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});
