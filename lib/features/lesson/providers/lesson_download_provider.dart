import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';

class LessonDownloadState {
  final bool isDownloaded;
  final bool isLoading;
  final String? error;

  LessonDownloadState({
    this.isDownloaded = false,
    this.isLoading = false,
    this.error,
  });

  LessonDownloadState copyWith({
    bool? isDownloaded,
    bool? isLoading,
    String? error,
  }) {
    return LessonDownloadState(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LessonDownloadNotifier extends StateNotifier<LessonDownloadState> {
  final Ref _ref;
  final String lessonId;
  final _dio = Dio();

  LessonDownloadNotifier(this._ref, this.lessonId) : super(LessonDownloadState()) {
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final lessonDir = Directory('${dir.path}/offline_lessons/$lessonId');
      final isDownloaded = await lessonDir.exists();
      
      state = state.copyWith(isDownloaded: isDownloaded);
    } catch (e) {
      state = state.copyWith(error: 'Error checking download status: $e');
    }
  }

  Future<void> downloadLesson(LessonModel lesson) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final lessonDir = Directory('${dir.path}/offline_lessons/${lesson.id}');
      
      // Create lesson directory
      if (!await lessonDir.exists()) {
        await lessonDir.create(recursive: true);
      }

      // Save lesson data
      await _saveLessonData(lesson, lessonDir);

      // Download video if available
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        await _downloadVideo(lesson.videoUrl!, lessonDir);
      }

      // Download audio if available
      if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty) {
        await _downloadAudio(lesson.audioUrl!, lessonDir);
      }

      // Download PDF content if available
      if (lesson.content.isNotEmpty) {
        await _downloadPDF(lesson.content, lessonDir);
      }

      // Download thumbnail if available
      if (lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty) {
        await _downloadThumbnail(lesson.thumbnailUrl!, lessonDir);
      }

      // Download quiz audio files if available
      await _downloadQuizAudioFiles(lesson, lessonDir);

      state = state.copyWith(isDownloaded: true, isLoading: false);
      _ref.invalidate(downloadedLessonIdsProvider);
      _ref.invalidate(downloadedLessonsCountProvider);
      _ref.invalidate(downloadedLessonsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Download failed: $e');
    }
  }

  Future<void> _saveLessonData(LessonModel lesson, Directory lessonDir) async {
    final lessonDataFile = File('${lessonDir.path}/lesson_data.json');
    final lessonData = lesson.toJson();
    await lessonDataFile.writeAsString(jsonEncode(lessonData));
  }

  Future<void> _downloadVideo(String videoUrl, Directory lessonDir) async {
    try {
      final videoFile = File('${lessonDir.path}/video.mp4');
      if (!await videoFile.exists()) {
        await _dio.download(videoUrl, videoFile.path);
      }
    } catch (e) {
      // Video download is optional, don't fail the entire download
      print('Failed to download video: $e');
    }
  }

  Future<void> _downloadAudio(String audioUrl, Directory lessonDir) async {
    try {
      final audioFile = File('${lessonDir.path}/audio.mp3');
      if (!await audioFile.exists()) {
        await _dio.download(audioUrl, audioFile.path);
      }
    } catch (e) {
      // Audio download is optional, don't fail the entire download
      print('Failed to download audio: $e');
    }
  }

  Future<void> _downloadPDF(String pdfUrl, Directory lessonDir) async {
    try {
      final pdfFile = File('${lessonDir.path}/content.pdf');
      if (!await pdfFile.exists()) {
        await _dio.download(pdfUrl, pdfFile.path);
      }
    } catch (e) {
      // PDF download is optional, don't fail the entire download
      print('Failed to download PDF: $e');
    }
  }

  Future<void> _downloadThumbnail(String thumbnailUrl, Directory lessonDir) async {
    try {
      final thumbnailFile = File('${lessonDir.path}/thumbnail.jpg');
      if (!await thumbnailFile.exists()) {
        await _dio.download(thumbnailUrl, thumbnailFile.path);
      }
    } catch (e) {
      // Thumbnail download is optional, don't fail the entire download
      print('Failed to download thumbnail: $e');
    }
  }

  Future<void> _downloadQuizAudioFiles(LessonModel lesson, Directory lessonDir) async {
    try {
      final quizAudioDir = Directory('${lessonDir.path}/quiz_audio');
      if (!await quizAudioDir.exists()) {
        await quizAudioDir.create();
      }

      for (final quiz in lesson.quizzes) {
        if (quiz.soundFileUrl != null && quiz.soundFileUrl!.isNotEmpty) {
          final fileName = quiz.soundFileUrl!.split('/').last;
          final audioFile = File('${quizAudioDir.path}/$fileName');
          
          if (!await audioFile.exists()) {
            await _dio.download(quiz.soundFileUrl!, audioFile.path);
          }
        }
      }
    } catch (e) {
      // Quiz audio download is optional, don't fail the entire download
      print('Failed to download quiz audio files: $e');
    }
  }

  Future<void> removeDownload() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final lessonDir = Directory('${dir.path}/offline_lessons/$lessonId');
      
      if (await lessonDir.exists()) {
        await lessonDir.delete(recursive: true);
      }
      
      state = state.copyWith(isDownloaded: false);
      _ref.invalidate(downloadedLessonIdsProvider);
      _ref.invalidate(downloadedLessonsCountProvider);
      _ref.invalidate(downloadedLessonsProvider);
    } catch (e) {
      state = state.copyWith(error: 'Error removing download: $e');
    }
  }

  Future<LessonModel?> getOfflineLesson() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final lessonDir = Directory('${dir.path}/offline_lessons/$lessonId');
      final lessonDataFile = File('${lessonDir.path}/lesson_data.json');
      
      if (await lessonDataFile.exists()) {
        final lessonData = await lessonDataFile.readAsString();
        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(lessonData) as Map<String, dynamic>;
        } catch (e) {
          // Fallback for legacy Map.toString() format
          final normalized = lessonData
              .replaceAll("'", '"')
              .replaceAllMapped(
                RegExp(r'([,{]\s*)([A-Za-z0-9_]+)\s*:'),
                (m) => '${m.group(1)}"${m.group(2)}":',
              );
          decoded = jsonDecode(normalized) as Map<String, dynamic>;
        }
        final videoFile = File('${lessonDir.path}/video.mp4');
        if (await videoFile.exists()) {
          decoded['video_url'] = videoFile.path;
        }
        final audioFile = File('${lessonDir.path}/audio.mp3');
        if (await audioFile.exists()) {
          decoded['audio_url'] = audioFile.path;
        }
        final pdfFile = File('${lessonDir.path}/content.pdf');
        if (await pdfFile.exists()) {
          decoded['content'] = pdfFile.path;
        }
        final thumbnailFile = File('${lessonDir.path}/thumbnail.jpg');
        if (await thumbnailFile.exists()) {
          decoded['thumbnail_url'] = thumbnailFile.path;
        }

        final quizzes = decoded['quizzes'];
        if (quizzes is List) {
          final updatedQuizzes = <Map<String, dynamic>>[];
          for (final quiz in quizzes) {
            if (quiz is Map<String, dynamic>) {
              final soundUrl = quiz['sound_file_url'] as String?;
              if (soundUrl != null && soundUrl.isNotEmpty) {
                final fileName = soundUrl.split('/').last;
                final localAudioFile =
                    File('${lessonDir.path}/quiz_audio/$fileName');
                if (await localAudioFile.exists()) {
                  quiz['sound_file_url'] = localAudioFile.path;
                }
              }
              updatedQuizzes.add(quiz);
            }
          }
          decoded['quizzes'] = updatedQuizzes;
        }

        return LessonModel.fromJson(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final lessonDownloadProvider = StateNotifierProvider.family<LessonDownloadNotifier, LessonDownloadState, String>(
  (ref, lessonId) => LessonDownloadNotifier(ref, lessonId),
);

// Provider to get offline lesson data
final offlineLessonProvider = FutureProvider.family<LessonModel?, String>((ref, lessonId) async {
  final downloadNotifier = ref.read(lessonDownloadProvider(lessonId).notifier);
  return await downloadNotifier.getOfflineLesson();
});

// Provider to check if lesson is available offline
final isLessonOfflineProvider = Provider.family<bool, String>((ref, lessonId) {
  final downloadState = ref.watch(lessonDownloadProvider(lessonId));
  return downloadState.isDownloaded;
});

// Provider to get count of all downloaded lessons
final downloadedLessonsCountProvider = FutureProvider<int>((ref) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final offlineLessonsDir = Directory('${dir.path}/offline_lessons');
    
    if (await offlineLessonsDir.exists()) {
      final lessonDirs = await offlineLessonsDir.list().toList();
      return lessonDirs.where((entity) => entity is Directory).length;
    }
    return 0;
  } catch (e) {
    print('Error getting downloaded lessons count: $e');
    return 0;
  }
});

// Provider to get list of all downloaded lesson IDs
final downloadedLessonIdsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final offlineLessonsDir = Directory('${dir.path}/offline_lessons');
    
    if (await offlineLessonsDir.exists()) {
      final lessonDirs = await offlineLessonsDir.list().toList();
      return lessonDirs
          .where((entity) => entity is Directory)
          .map((entity) => entity.path.split('/').last)
          .toList();
    }
    return [];
  } catch (e) {
    print('Error getting downloaded lesson IDs: $e');
    return [];
  }
}); 

// Provider to get a list of downloaded lessons (limited for UI previews)
final downloadedLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final ids = await ref.watch(downloadedLessonIdsProvider.future);
  if (ids.isEmpty) {
    return [];
  }

  final limitedIds = ids.take(4).toList();
  final lessons = await Future.wait(
    limitedIds.map((id) => ref.read(offlineLessonProvider(id).future)),
  );
  return lessons.whereType<LessonModel>().toList();
});
