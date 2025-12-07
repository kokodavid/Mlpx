import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Audio Cache State
class AudioCacheState {
  final Map<String, String> cachedFiles; // audioPath -> localFilePath
  final bool isLoading;
  final String? error;

  const AudioCacheState({
    this.cachedFiles = const {},
    this.isLoading = false,
    this.error,
  });

  AudioCacheState copyWith({
    Map<String, String>? cachedFiles,
    bool? isLoading,
    String? error,
  }) {
    return AudioCacheState(
      cachedFiles: cachedFiles ?? this.cachedFiles,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool isCached(String audioPath) {
    return cachedFiles.containsKey(audioPath);
  }

  String? getCachedPath(String audioPath) {
    return cachedFiles[audioPath];
  }
}

// Audio Cache Notifier
class AudioCacheNotifier extends StateNotifier<AudioCacheState> {
  AudioCacheNotifier() : super(const AudioCacheState());

  // Cache an audio file
  Future<void> cacheAudioFile(String audioPath, String localFilePath) async {
    try {
      print('AudioCache: Caching audio file: $audioPath -> $localFilePath');
      state = state.copyWith(isLoading: true, error: null);
      
      // Verify the file exists
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('AudioCache: Error - File not found at $localFilePath');
        throw Exception('Audio file not found at $localFilePath');
      }

      // Get file size for logging
      final fileSize = await file.length();
      print('AudioCache: File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

      // Add to cached files
      final newCachedFiles = Map<String, String>.from(state.cachedFiles);
      newCachedFiles[audioPath] = localFilePath;
      
      state = state.copyWith(
        cachedFiles: newCachedFiles,
        isLoading: false,
      );
      
      print('AudioCache: Successfully cached audio file: $audioPath');
      print('AudioCache: Total cached files: ${newCachedFiles.length}');
    } catch (e) {
      print('AudioCache: Error caching audio file: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cache audio file: $e',
      );
    }
  }

  // Remove a specific cached file
  Future<void> removeCachedFile(String audioPath) async {
    try {
      final localFilePath = state.cachedFiles[audioPath];
      if (localFilePath != null) {
        final file = File(localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        final newCachedFiles = Map<String, String>.from(state.cachedFiles);
        newCachedFiles.remove(audioPath);
        
        state = state.copyWith(cachedFiles: newCachedFiles);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove cached file: $e');
    }
  }

  // Clear all cached files
  Future<void> clearCache() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      for (final localFilePath in state.cachedFiles.values) {
        try {
          final file = File(localFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Continue with other files even if one fails
          print('Error deleting cached file $localFilePath: $e');
        }
      }
      
      state = state.copyWith(
        cachedFiles: const {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear cache: $e',
      );
    }
  }

  // Get cache size
  Future<int> getCacheSize() async {
    int totalSize = 0;
    for (final localFilePath in state.cachedFiles.values) {
      try {
        final file = File(localFilePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        // Skip files that can't be accessed
        continue;
      }
    }
    return totalSize;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final audioCacheProvider = StateNotifierProvider<AudioCacheNotifier, AudioCacheState>((ref) {
  return AudioCacheNotifier();
}); 