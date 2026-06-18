import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'audio_player_provider.dart';
import 'audio_cache_provider.dart';
import 'audio_service_provider.dart';

// Audio Session State
class AudioSessionState {
  final String? activeScreenId;
  final String? currentAudioPath;
  final bool isPlaying;
  final bool isLoading;
  final bool isPaused;
  final Map<String, String> screenAudioMap; // screenId -> audioPath
  final String? error;

  const AudioSessionState({
    this.activeScreenId,
    this.currentAudioPath,
    this.isPlaying = false,
    this.isLoading = false,
    this.isPaused = false,
    this.screenAudioMap = const {},
    this.error,
  });

  AudioSessionState copyWith({
    String? activeScreenId,
    String? currentAudioPath,
    bool? isPlaying,
    bool? isLoading,
    bool? isPaused,
    Map<String, String>? screenAudioMap,
    String? error,
  }) {
    return AudioSessionState(
      activeScreenId: activeScreenId ?? this.activeScreenId,
      currentAudioPath: currentAudioPath ?? this.currentAudioPath,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isPaused: isPaused ?? this.isPaused,
      screenAudioMap: screenAudioMap ?? this.screenAudioMap,
      error: error ?? this.error,
    );
  }

  // Check if a specific screen has active audio
  bool isScreenActive(String screenId) {
    return activeScreenId == screenId;
  }

  // Get audio path for a specific screen
  String? getScreenAudioPath(String screenId) {
    return screenAudioMap[screenId];
  }
}

// Audio Session Notifier
class AudioSessionNotifier extends StateNotifier<AudioSessionState> {
  final Ref ref;

  AudioSessionNotifier(this.ref) : super(const AudioSessionState()) {
    // Listen to audio player state changes
    ref.listen<AudioPlayerState>(
      audioPlayerProvider,
      (previous, next) {
        // Update session state based on audio player state
        state = state.copyWith(
          isPlaying: next.isPlaying,
          isLoading: next.isLoading,
        );
      },
    );
  }

  // Register a screen's audio
  Future<void> registerScreenAudio({
    required String screenId,
    required String audioPath,
  }) async {
    try {
      print('AudioSession: Registering audio for screen $screenId: $audioPath');
      
      // Check if this audio is already cached
      final cacheState = ref.read(audioCacheProvider);
      final isCached = cacheState.isCached(audioPath);
      print('AudioSession: Audio already cached: $isCached');
      
      // Update screen audio mapping
      final newScreenAudioMap = Map<String, String>.from(state.screenAudioMap);
      newScreenAudioMap[screenId] = audioPath;
      
      state = state.copyWith(
        screenAudioMap: newScreenAudioMap,
        activeScreenId: screenId,
        currentAudioPath: audioPath,
      );

      print('AudioSession: Successfully registered audio for screen $screenId: $audioPath');
      print('AudioSession: Total registered screens: ${newScreenAudioMap.length}');
    } catch (e) {
      print('AudioSession: Error registering audio for screen $screenId: $e');
      state = state.copyWith(error: 'Failed to register screen audio: $e');
    }
  }

  // Start audio session for a screen
  Future<void> startSession(String screenId) async {
    try {
      print('AudioSession: Starting session for screen $screenId');
      
      // Stop any current session
      await _stopCurrentSession();

      // Get audio path for this screen
      final audioPath = state.getScreenAudioPath(screenId);
      print('AudioSession: Audio path for screen $screenId: $audioPath');
      
      if (audioPath == null) {
        print('AudioSession: No audio registered for screen $screenId');
        throw Exception('No audio registered for screen $screenId');
      }

      // Check if audio is cached
      final cacheState = ref.read(audioCacheProvider);
      final isCached = cacheState.isCached(audioPath);
      print('AudioSession: Audio cached: $isCached');

      // Set this screen as active
      state = state.copyWith(
        activeScreenId: screenId,
        currentAudioPath: audioPath,
        isLoading: true,
        isPaused: false,
      );

      print('AudioSession: Playing audio for screen $screenId: $audioPath');

      // Play the audio
      await ref.read(audioServiceProvider.notifier).playAudio(audioPath);

      state = state.copyWith(isLoading: false);
      print('AudioSession: Session started successfully for screen $screenId');
    } catch (e) {
      print('AudioSession: Error starting session for screen $screenId: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start session: $e',
      );
    }
  }

  // Stop current session
  Future<void> _stopCurrentSession() async {
    try {
      if (state.activeScreenId != null && state.isPlaying) {
        print('AudioSession: Stopping session for screen ${state.activeScreenId}');
        
        await ref.read(audioServiceProvider.notifier).stopAudio();
        
        // Don't remove cached files - keep them for reuse
        print('AudioSession: Keeping cached audio files for reuse');
      }

      state = state.copyWith(
        activeScreenId: null,
        currentAudioPath: null,
        isPlaying: false,
        isLoading: false,
        isPaused: false,
      );
    } catch (e) {
      print('AudioSession: Error stopping session: $e');
    }
  }

  // Play audio (only if screen is active)
  Future<void> playAudio(String screenId) async {
    if (!state.isScreenActive(screenId)) {
      print('AudioSession: Cannot play audio - screen $screenId is not active');
      return;
    }

    try {
      state = state.copyWith(isPaused: false);
      await ref.read(audioServiceProvider.notifier).playAudio(state.currentAudioPath!);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play audio: $e');
    }
  }

  // Pause audio (only if screen is active)
  Future<void> pauseAudio(String screenId) async {
    if (!state.isScreenActive(screenId)) {
      print('AudioSession: Cannot pause audio - screen $screenId is not active');
      return;
    }

    try {
      await ref.read(audioServiceProvider.notifier).pauseAudio();
      state = state.copyWith(isPaused: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause audio: $e');
    }
  }

  // Resume audio (only if screen is active)
  Future<void> resumeAudio(String screenId) async {
    if (!state.isScreenActive(screenId)) {
      print(
        'AudioSession: Cannot resume audio - screen $screenId is not active',
      );
      return;
    }

    try {
      state = state.copyWith(isPaused: false);
      await ref.read(audioServiceProvider.notifier).resumeAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume audio: $e');
    }
  }

  // Replay audio (only if screen is active)
  Future<void> replayAudio(String screenId) async {
    if (!state.isScreenActive(screenId)) {
      print('AudioSession: Cannot replay audio - screen $screenId is not active');
      return;
    }

    try {
      state = state.copyWith(isPaused: false);
      await ref.read(audioServiceProvider.notifier).replayAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to replay audio: $e');
    }
  }

  // Stop session for a specific screen
  Future<void> stopSession(String screenId) async {
    if (state.activeScreenId == screenId) {
      await _stopCurrentSession();
    }
  }

  // Get audio state for a specific screen
  AudioState getScreenAudioState(String screenId) {
    final audioPath = state.getScreenAudioPath(screenId);
    final isActive = state.isScreenActive(screenId);
    final isCached =
        audioPath != null && ref.read(audioCacheProvider).isCached(audioPath);
    
    return AudioState(
      isCached: isCached,
      isPlaying: isActive && state.isPlaying,
      isLoading: isActive && state.isLoading,
      isPaused: isActive && state.isPaused,
      error: state.error,
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Audio State for a specific screen
class AudioState {
  final bool isCached;
  final bool isPlaying;
  final bool isLoading;
  final bool isPaused;
  final String? error;

  const AudioState({
    this.isCached = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.isPaused = false,
    this.error,
  });
}

// Provider
final audioSessionProvider =
    StateNotifierProvider<AudioSessionNotifier, AudioSessionState>((ref) {
  return AudioSessionNotifier(ref);
});
