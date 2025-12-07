import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/supabase_config.dart';
import 'audio_player_provider.dart';
import 'audio_cache_provider.dart';

// Audio Service State
class AudioServiceState {
  final bool isDownloading;
  final double downloadProgress;
  final String? error;

  const AudioServiceState({
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.error,
  });

  AudioServiceState copyWith({
    bool? isDownloading,
    double? downloadProgress,
    String? error,
  }) {
    return AudioServiceState(
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
    );
  }
}

// Audio Service Notifier
class AudioServiceNotifier extends StateNotifier<AudioServiceState> {
  final Ref ref;
  final Dio _dio = Dio();

  AudioServiceNotifier(this.ref) : super(const AudioServiceState());

  // Download and cache audio file from Supabase storage
  Future<void> downloadAndCacheAudio(String audioPath) async {
    try {
      print('AudioService: Starting download for: $audioPath');
      
      state = state.copyWith(
        isDownloading: true,
        downloadProgress: 0.0,
        error: null,
      );

      String audioUrl;
      String fileName;
      
      if (audioPath.startsWith('http')) {
        audioUrl = audioPath;
        fileName = Uri.parse(audioPath).pathSegments.last;
        print('AudioService: Using full URL: $audioUrl');
      } else {
        final cleanPath = _cleanStoragePath(audioPath);
        print('AudioService: Cleaned path: $cleanPath');
        
        audioUrl = SupabaseConfig.client
            .storage
            .from('assessment-sounds')
            .getPublicUrl(cleanPath);
        fileName = cleanPath.split('/').last;
        print('AudioService: Generated URL: $audioUrl');
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      print('AudioService: Local file path: $filePath');

      final file = File(filePath);
      if (await file.exists()) {
        await ref.read(audioCacheProvider.notifier).cacheAudioFile(audioPath, filePath);
        state = state.copyWith(isDownloading: false);
        return;
      }

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            state = state.copyWith(downloadProgress: progress);
          }
        },
      );

      await ref.read(audioCacheProvider.notifier).cacheAudioFile(audioPath, filePath);

      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'Failed to download audio: $e',
      );
      rethrow;
    }
  }

  Future<void> playAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await ref.read(audioPlayerProvider.notifier).playAudio(audioPath);
        return;
      }

      final cacheState = ref.read(audioCacheProvider);
      if (!cacheState.isCached(audioPath)) {
        await downloadAndCacheAudio(audioPath);
      }

      final cachedPath = cacheState.getCachedPath(audioPath);
      if (cachedPath == null) {
        throw Exception('Audio file not found in cache');
      }

      await ref.read(audioPlayerProvider.notifier).playAudio(cachedPath);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await ref.read(audioPlayerProvider.notifier).pauseAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause audio: $e');
    }
  }

  Future<void> resumeAudio() async {
    try {
      await ref.read(audioPlayerProvider.notifier).resumeAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume audio: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await ref.read(audioPlayerProvider.notifier).stopAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop audio: $e');
    }
  }

  Future<void> replayAudio() async {
    try {
      await ref.read(audioPlayerProvider.notifier).replayAudio();
    } catch (e) {
      state = state.copyWith(error: 'Failed to replay audio: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await ref.read(audioCacheProvider.notifier).clearCache();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear cache: $e');
    }
  }

  bool isAudioPlaying(String storagePath) {
    final playerState = ref.read(audioPlayerProvider);
    final cacheState = ref.read(audioCacheProvider);
    final cachedPath = cacheState.getCachedPath(storagePath);
    
    return playerState.isPlaying && 
           playerState.currentAudioPath == cachedPath;
  }

  AudioState getAudioState(String storagePath) {
    final playerState = ref.read(audioPlayerProvider);
    final cacheState = ref.read(audioCacheProvider);
    final isCached = cacheState.isCached(storagePath);
    final isPlaying = isAudioPlaying(storagePath);
    final isLoading = playerState.isLoading || state.isDownloading;

    return AudioState(
      isCached: isCached,
      isPlaying: isPlaying,
      isLoading: isLoading,
      error: playerState.error ?? state.error,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
    ref.read(audioPlayerProvider.notifier).clearError();
    ref.read(audioCacheProvider.notifier).clearError();
  }

  String _cleanStoragePath(String path) {
    if (path.startsWith('http')) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    
    path = path.replaceFirst(RegExp(r'^/+'), '');
    path = path.replaceAll(RegExp(r'/+'), '/');
    path = path.replaceAll(RegExp(r'/+$'), '');
    return path;
  }
}

class AudioState {
  final bool isCached;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  const AudioState({
    this.isCached = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });
}

final audioServiceProvider = StateNotifierProvider<AudioServiceNotifier, AudioServiceState>((ref) {
  return AudioServiceNotifier(ref);
}); 