import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/lesson/lesson_widgets/lesson_action_button.dart';
import 'package:milpress/features/lesson/lesson_widgets/video_player_widget.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lesson/providers/lesson_video_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/features/assessment/models/assessment_config.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
import 'package:milpress/features/reviews/providers/bookmark_provider.dart';
import 'package:milpress/features/lesson/providers/lesson_download_provider.dart';
import 'package:milpress/providers/audio_service_provider.dart';
import 'package:share_plus/share_plus.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _isPrefetchingQuizAudio = false;
  double _prefetchProgress = 0.0;
  String? _prefetchError;
  bool _isCompletingLesson = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      if (context.mounted) {
        final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final courseContext = extra?['courseContext'] as Map<String, dynamic>?;
        if (courseContext != null) {
          final moduleId = courseContext['moduleId'] as String?;
          if (moduleId != null) {
            ref
                .read(moduleQuizProgressProvider(moduleId).notifier)
                .loadModuleProgress(moduleId);
          }
        }
      }
    });
  }

  void _videoEndListener(VideoPlayerController controller, WidgetRef ref) {
    if (controller.value.position >= controller.value.duration &&
        ref.read(lessonVideoPlaybackProvider)) {
      ref.read(lessonVideoPlaybackProvider.notifier).state = false;
    }
  }

  void _setupVideoListener(VideoPlayerController controller) {
    controller.addListener(() => _videoEndListener(controller, ref));
  }

  Future<bool> _prefetchQuizAudio(List<Map<String, dynamic>> questions) async {
    if (!mounted) return false;

    setState(() {
      _isPrefetchingQuizAudio = true;
      _prefetchProgress = 0.0;
      _prefetchError = null;
    });

    try {
      // Extract audio URLs from questions
      final audioUrls = questions
          .where((q) => q['sound_file_url'] != null && q['sound_file_url'].toString().isNotEmpty)
          .map((q) => q['sound_file_url'].toString())
          .toList();

      if (audioUrls.isEmpty) {
        // No audio to prefetch, we can proceed immediately
        if (mounted) {
          setState(() {
            _isPrefetchingQuizAudio = false;
            _prefetchProgress = 1.0;
          });
        }
        return true;
      }

      print('LessonScreen: Prefetching ${audioUrls.length} quiz audio files');

      // Prefetch each audio file
      for (int i = 0; i < audioUrls.length; i++) {
        if (!mounted) return false;

        try {
          await ref.read(audioServiceProvider.notifier).downloadAndCacheAudio(audioUrls[i]);
          
          if (mounted) {
            setState(() {
              _prefetchProgress = (i + 1) / audioUrls.length;
            });
          }
          
          print('LessonScreen: Prefetched audio ${i + 1}/${audioUrls.length}: ${audioUrls[i]}');
        } catch (e) {
          print('LessonScreen: Failed to prefetch audio ${audioUrls[i]}: $e');
          // Continue with next audio file - don't fail entire process
        }
      }

      if (mounted) {
        setState(() {
          _isPrefetchingQuizAudio = false;
          _prefetchProgress = 1.0;
        });
      }

      print('LessonScreen: Quiz audio prefetching completed successfully');
      return true;

    } catch (e) {
      print('LessonScreen: Error during quiz audio prefetching: $e');
      
      if (mounted) {
        setState(() {
          _isPrefetchingQuizAudio = false;
          _prefetchError = 'Failed to prepare quiz audio: $e';
        });
      }
      
      return false;
    }
  }

  void _resetPrefetchState() {
    if (mounted) {
      setState(() {
        _isPrefetchingQuizAudio = false;
        _prefetchProgress = 0.0;
        _prefetchError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonFromSupabaseProvider(widget.lessonId));
    
    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return const Scaffold(
            body: Center(child: Text('Lesson not found')),
          );
        }

        return Builder(
          builder: (context) {
            final videoUrl = lesson.videoUrl ?? '';
            final videoControllerAsync =
                ref.watch(lessonVideoPlayerControllerProvider(videoUrl));
            final isPlaying = ref.watch(lessonVideoPlaybackProvider);

            final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
            final courseContext = extra?['courseContext'] as Map<String, dynamic>?;
            final moduleId = courseContext?['moduleId'] as String?;
            
            final moduleProgress = moduleId != null 
                ? ref.watch(moduleQuizProgressProvider(moduleId))
                : null;
            
            final lessonScore = moduleProgress?.lessonScores[lesson.id];
            final isQuizCompleted = lessonScore != null && lessonScore.isCompleted;
            final quizScore = lessonScore?.score ?? 0;
            final totalQuestions = lessonScore?.totalQuestions ?? lesson.quizzes.length;

            return Scaffold(
              backgroundColor: AppColors.sandyLight,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    final extra = GoRouterState.of(context).extra
                        as Map<String, dynamic>?;
                    final courseContext =
                        extra?['courseContext'] as Map<String, dynamic>?;
                    final courseId = courseContext?['courseId'] as String?;
                    if (courseId != null && courseId.isNotEmpty) {
                      context.go('/course/$courseId');
                    } else {
                      context.pop();
                    }
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
                centerTitle: true,
                title: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (videoUrl.isNotEmpty) ...[
                        videoControllerAsync.when(
                          data: (controller) {
                            _setupVideoListener(controller);
                            
                            if (isPlaying && !controller.value.isPlaying) {
                              controller.play();
                            } else if (!isPlaying &&
                                controller.value.isPlaying) {
                              controller.pause();
                            }
                            return VideoPlayerWidget(
                              videoUrl: videoUrl,
                              externalController: controller,
                            );
                          },
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => const SizedBox(
                            height: 200,
                            child: Center(child: Text('Error loading video')),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10, size: 32),
                              onPressed: () {
                                final controller = ref
                                    .read(lessonVideoPlayerControllerProvider(
                                        videoUrl))
                                    .maybeWhen(
                                      data: (c) => c,
                                      orElse: () => null,
                                    );
                                if (controller != null) {
                                  final newPosition =
                                      controller.value.position -
                                          const Duration(seconds: 10);
                                  controller.seekTo(newPosition > Duration.zero
                                      ? newPosition
                                      : Duration.zero);
                                }
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  size: 48,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  ref
                                      .read(
                                          lessonVideoPlaybackProvider.notifier)
                                      .state = !isPlaying;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10, size: 32),
                              onPressed: () {
                                final controller = ref
                                    .read(lessonVideoPlayerControllerProvider(
                                        videoUrl))
                                    .maybeWhen(
                                      data: (c) => c,
                                      orElse: () => null,
                                    );
                                if (controller != null) {
                                  final max = controller.value.duration;
                                  final newPosition =
                                      controller.value.position +
                                          const Duration(seconds: 10);
                                  controller.seekTo(
                                      newPosition < max ? newPosition : max);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final downloadState = ref.watch(lessonDownloadProvider(lesson.id));
                              
                              return LessonActionButton(
                                icon: downloadState.isDownloaded ? Icons.download_done : Icons.download,
                                label: downloadState.isLoading 
                                    ? 'Downloading...' 
                                    : downloadState.isDownloaded 
                                        ? 'Downloaded' 
                                        : 'Download',
                                onTap: downloadState.isLoading 
                                    ? () {} 
                                    : () {
                                        if (downloadState.isDownloaded) {
                                          // Show already downloaded message
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Lesson already downloaded for offline access'),
                                                backgroundColor: Colors.blue,
                                              ),
                                            );
                                          }
                                        } else {
                                          // Start download
                                          ref.read(lessonDownloadProvider(lesson.id).notifier).downloadLesson(lesson).then((_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Lesson downloaded successfully for offline access'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          });
                                        }
                                      },
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final isBookmarkedAsync = ref.watch(isLessonBookmarkedProvider(lesson.id));
                              
                              return isBookmarkedAsync.when(
                                data: (isBookmarked) => LessonActionButton(
                                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  iconColor: isBookmarked
                                      ? AppColors.correctAnswerColor
                                      : null,
                                  
                                  label: isBookmarked ? 'Saved' : 'Save',
                                  onTap: () async {
                                    try {
                                      if (isBookmarked) {
                                        await ref.read(removeBookmarkProvider(lesson.id).future);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Removed from bookmarks'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      } else {
                                        final courseContext = extra?['courseContext'] as Map<String, dynamic>?;
                                        final courseId = courseContext?['courseId'] as String?;
                                        final courseTitle = courseContext?['courseTitle'] as String?;
                                        final moduleId = courseContext?['moduleId'] as String?;
                                        final moduleTitle = courseContext?['moduleTitle'] as String?;
                                        
                                        if (courseId != null && courseTitle != null && moduleId != null && moduleTitle != null) {
                                          await ref.read(addBookmarkProvider({
                                            'lessonId': lesson.id,
                                            'courseId': courseId,
                                            'moduleId': moduleId,
                                            'lessonTitle': lesson.title,
                                            'courseTitle': courseTitle,
                                            'moduleTitle': moduleTitle,
                                          }).future);
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Added to bookmarks'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Unable to bookmark: Missing course information'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                loading: () => LessonActionButton(
                                  icon: Icons.bookmark_border,
                                  label: 'Save',
                                  onTap: () {},
                                ),
                                error: (_, __) => LessonActionButton(
                                  icon: Icons.bookmark_border,
                                  label: 'Save',
                                  onTap: () {},
                                ),
                              );
                            },
                          ),
                          LessonActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () {
                              const appLink =
                                  'https://play.google.com/store/apps/details?id=com.milpress.edu';
                              final courseContext =
                                  extra?['courseContext'] as Map<String, dynamic>?;
                              final courseTitle = courseContext?['courseTitle'] as String?;
                              final moduleTitle = courseContext?['moduleTitle'] as String?;
                              final contextText = [
                                if (courseTitle != null && courseTitle.isNotEmpty)
                                  courseTitle,
                                if (moduleTitle != null && moduleTitle.isNotEmpty)
                                  moduleTitle,
                              ].join(' • ');
                              final shareText = contextText.isEmpty
                                  ? 'I just completed "${lesson.title}" on Millpress. Download the app: $appLink'
                                  : 'I just completed "${lesson.title}" in $contextText on Millpress. Download the app: $appLink';
                              SharePlus.instance.share(ShareParams(text: shareText));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isQuizCompleted) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quiz Completed!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'Score: $quizScore/$totalQuestions',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (lesson.quizzes.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            if (isQuizCompleted) {
                              return const SizedBox.shrink();
                            }
                            
                            return Column(
                              children: [
                                // Show prefetching progress if in progress
                                if (_isPrefetchingQuizAudio) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                value: _prefetchProgress,
                                                strokeWidth: 2,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Preparing quiz audio...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: _prefetchProgress,
                                          backgroundColor: Colors.blue.withOpacity(0.2),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_prefetchProgress * 100).toStringAsFixed(0)}% complete',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Show error if prefetching failed
                                if (_prefetchError != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Audio preparation failed. Quiz will work but may load slower.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                CustomButton(
                                  onPressed: _isPrefetchingQuizAudio ? null : () async {
                                    final questions = lesson.quizzes
                                        .map((quiz) => {
                                              'id': quiz.id,
                                              'stage': quiz.stage,
                                              'question_type': quiz.questionType,
                                              'question_content': quiz.questionContent,
                                              'sound_file_url': quiz.soundFileUrl,
                                              'correct_answer': quiz.correctAnswer,
                                              'options': quiz.options,
                                              'difficulty_level': quiz.difficultyLevel,
                                            })
                                        .toList();

                                    // Prefetch audio first, then navigate
                                    final prefetchSuccess = await _prefetchQuizAudio(questions);
                                    
                                    if (mounted && (prefetchSuccess || _prefetchError != null)) {
                                      // Navigate even if prefetch failed (graceful degradation)
                                      context.push('/assessment', extra: {
                                        'questions': questions,
                                        'config': AssessmentConfig.lessonQuiz(
                                          lessonId: lesson.id,
                                          onQuizComplete: (result) {
                                            if (courseContext != null) {
                                              final moduleId = courseContext['moduleId'] as String?;
                                              if (moduleId != null) {
                                                final score = result['score'] as int;
                                                final totalQuestions = result['totalQuestions'] as int;
                                                
                                                ref
                                                    .read(moduleQuizProgressProvider(moduleId).notifier)
                                                    .updateLessonQuizScore(
                                                        lesson.id,
                                                        lesson.title,
                                                        score,
                                                        totalQuestions);
                                              }
                                            }

                                            if (context.mounted) {
                                              context.pop();
                                            }
                                          },
                                        ),
                                        'courseContext': courseContext,
                                      });
                                    }
                                  },
                                  isFilled: true,
                                  fillColor: AppColors.copBlue,
                                  outlineColor: AppColors.correctAnswerColor,
                                  text: 'Attempt ${lesson.quizzes.length} question${lesson.quizzes.length == 1 ? '' : 's'}',
                                  textColor: Colors.white,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
                          final courseContext = extra?['courseContext'] as Map<String, dynamic>?;
                          final isFromBookmark = courseContext?['isFromBookmark'] as bool? ?? false;
                          
                          if (isFromBookmark) {
                            return const SizedBox.shrink();
                          }
                            
                          return Column(
                            children: [
                              CustomButton(
                                onPressed: (_isCompletingLesson ||
                                        (lesson.quizzes.isNotEmpty && !isQuizCompleted))
                                    ? null
                                    : () async {
                                        if (_isCompletingLesson) {
                                          return;
                                        }
                                        setState(() {
                                          _isCompletingLesson = true;
                                        });
                                        try {
                                        final extra = GoRouterState.of(context).extra
                                            as Map<String, dynamic>?;
                                        final courseContext =
                                            extra?['courseContext'] as Map<String, dynamic>?;

                                        if (courseContext != null) {
                                          final courseId =
                                              courseContext['courseId'] as String?;
                                          final moduleId =
                                              courseContext['moduleId'] as String?;
                                          final currentLessonIndex =
                                              courseContext['currentLessonIndex'] as int? ??
                                                  0;
                                          final currentModuleIndex =
                                              courseContext['currentModuleIndex'] as int? ??
                                                  0;

                                          final isLastLessonInModule = currentLessonIndex == 
                                              (courseContext['moduleLessonsCount'] as int? ?? 1) - 1;

                                          final completedCount = currentLessonIndex + 1;

                                          if (courseId == null || courseId.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Error: Course ID not found.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          final userAsync = ref.read(authProvider);
                                          final userId = userAsync.asData?.value?.id;
                                          if (userId == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Error: User not found.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          final uuid = Uuid().v4();
                                          final now = DateTime.now();
                                          
                                          String courseProgressId = '';
                                          if (courseId != null) {
                                            try {
                                              courseProgressId = await ref.read(getOrCreateCourseProgressProvider(courseId).future);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error creating course progress: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                          }
                                          if (courseProgressId.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Error: Missing course progress.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          
                                          final lessonProgress = LessonProgressModel(
                                            id: uuid,
                                            userId: userId,
                                            lessonId: lesson.id,
                                            courseProgressId: courseProgressId,
                                            moduleId: moduleId,
                                            status: 'completed',
                                            startedAt: null,
                                            completedAt: now,
                                            videoProgress: null,
                                            quizScore: quizScore,
                                            quizAttemptedAt: now,
                                            createdAt: now,
                                            updatedAt: now,
                                            needsSync: true,
                                            quizTotalQuestions: totalQuestions,
                                            lessonTitle: lesson.title,
                                          );
                                          await ref.read(saveLessonProgressProvider(lessonProgress).future);

                                          context.push(
                                            '/lesson-complete/${lesson.id}',
                                            extra: {
                                              'lessonTitle': lesson.title,
                                              'isLastLesson': isLastLessonInModule,
                                              'completedCount': completedCount,
                                              'totalCount': courseContext['moduleLessonsCount'] as int? ?? 1,
                                              'courseId': courseId,
                                              'moduleId': moduleId,
                                              'currentLessonIndex': currentLessonIndex,
                                              'currentModuleIndex': currentModuleIndex,
                                              'isModuleComplete': isLastLessonInModule,
                                              'lessonId': lesson.id,
                                            },
                                          );
                                        } else {
                                          // Handle Jump In navigation - save progress and return to home
                                          final userAsync = ref.read(authProvider);
                                          final userId = userAsync.asData?.value?.id;
                                          if (userId == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Error: User not found.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          
                                          final uuid = Uuid().v4();
                                          final now = DateTime.now();
                                          
                                          final lessonProgress = LessonProgressModel(
                                            id: uuid,
                                            userId: userId,
                                            lessonId: lesson.id,
                                            courseProgressId: '', // No course context for Jump In
                                            moduleId: moduleId,
                                            status: 'completed',
                                            startedAt: null,
                                            completedAt: now,
                                            videoProgress: null,
                                            quizScore: quizScore,
                                            quizAttemptedAt: now,
                                            createdAt: now,
                                            updatedAt: now,
                                            needsSync: true,
                                            quizTotalQuestions: totalQuestions,
                                            lessonTitle: lesson.title,
                                          );
                                          
                                          await ref.read(saveLessonProgressProvider(lessonProgress).future);
                                          
                                          // Show success message and pop back to home
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${lesson.title} completed successfully!'),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                            
                                            // Pop back to home screen
                                            context.pop();
                                          }
                                        }
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isCompletingLesson = false;
                                            });
                                          }
                                        }
                                      },
                                text: (lesson.quizzes.isNotEmpty && !isQuizCompleted)
                                    ? 'Complete Quiz First'
                                    : 'Complete Lesson',
                                isLoading: _isCompletingLesson,
                                fillColor: _isCompletingLesson
                                    ? Colors.grey
                                    : (lesson.quizzes.isNotEmpty && !isQuizCompleted)
                                        ? AppColors.textColor.withOpacity(0.5)
                                        : AppColors.primaryColor,
                              ),
                              if (lesson.quizzes.isNotEmpty && !isQuizCompleted) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Complete the quiz above to finish this lesson',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Error loading lesson')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
