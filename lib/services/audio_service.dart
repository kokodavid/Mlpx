import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../utils/supabase_config.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _localFilePath;
  bool _isLoading = false;

  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isLoading => _isLoading;

  // Prefetch and cache the audio file
  Future<void> prefetchAudio(String storagePath) async {
    try {
      _isLoading = true;
      
      // Clean up the storage path by removing any double slashes
      final cleanPath = storagePath.replaceAll(RegExp(r'\/+'), '/');
      
      final audioUrl = SupabaseConfig.client
          .storage
          .from('assessment-sounds')
          .getPublicUrl(cleanPath);

      print('Fetching audio from: $audioUrl'); // Debug log

      final dir = await getTemporaryDirectory();
      final fileName = cleanPath.split('/').last;
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      if (!await file.exists()) {
        final response = await Dio().download(
          audioUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
            }
          },
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download audio file: ${response.statusCode}');
        }
      }
      
      _localFilePath = filePath;
      print('Audio file cached at: $_localFilePath'); // Debug log
    } catch (e) {
      print('Error prefetching audio: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> playCachedAudio() async {
    try {
      if (_localFilePath == null) {
        throw Exception('Audio not prefetched!');
      }
      
      print('Playing audio from: $_localFilePath'); // Debug log
      
      await _audioPlayer.setFilePath(_localFilePath!);
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping audio: $e');
      rethrow;
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    _audioPlayer.dispose();
  }
} 
