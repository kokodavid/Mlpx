import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/features/user_progress/models/module_progress_model.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:uuid/uuid.dart';

class CompleteLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const CompleteLessonScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  ConsumerState<CompleteLessonScreen> createState() =>
      _CompleteLessonScreenState();
}

class _CompleteLessonScreenState extends ConsumerState<CompleteLessonScreen> {
  bool _isProcessing = false;
  String _progressMessage = '';
  bool _isPrefetchingNextLesson = false;

  Future<void> _goToNextLesson(
    BuildContext context, {
    required CompleteCourseModel course,
    required ModuleWithLessons currentModule,
    required List<LessonModel> sortedLessons,
    required int currentLessonIndex,
    required Set<String> completedLessonIds,
  }) async {
    if (_isPrefetchingNextLesson) {
      return;
    }
    setState(() {
      _isPrefetchingNextLesson = true;
    });

    final courseId = course.course.id;
    final moduleId = currentModule.module.id;
    final currentLessonId = widget.lessonId;
    final currentModuleIndex = course.modules
        .indexWhere((module) => module.module.id == moduleId);
    final resolvedModuleIndex = currentModuleIndex >= 0 ? currentModuleIndex : 0;

    try {
      if (!completedLessonIds.contains(currentLessonId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete this lesson before continuing.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Look up courseProgressId for this user and course
      String? courseProgressId;
      final user = SupabaseConfig.currentUser;
      final userId = user?.id;
      if (userId != null) {
        try {
          final response = await SupabaseConfig.client
              .from('course_progress')
              .select('id')
              .eq('user_id', userId)
              .eq('course_id', courseId)
              .limit(1);

          if (response is List && response.isNotEmpty) {
            courseProgressId = response.first['id'] as String?;
          }
        } catch (e) {
          debugPrint('Error fetching course progress ID: $e');
        }
      }

      // Check if there's a next lesson in the current module
      if (currentLessonIndex < sortedLessons.length - 1) {
        final nextLesson = sortedLessons[currentLessonIndex + 1];

        try {
          await ref.read(
            lessonFromSupabaseProvider(nextLesson.id).future,
          );
        } catch (e) {
          debugPrint('CompleteLessonScreen: error prefetching next lesson: $e');
        }

        context.pushReplacement('/lesson/${nextLesson.id}', extra: {
          'courseContext': {
            'courseId': courseId,
            'courseTitle': course.course.title,
            'moduleId': moduleId,
            'moduleTitle': currentModule.module.description,
            'totalModules': course.modules.length,
            'totalLessons':
                course.modules.fold(0, (sum, m) => sum + m.lessons.length),
            'currentLessonIndex': currentLessonIndex + 1,
            'currentModuleIndex': resolvedModuleIndex,
            'moduleLessonsCount': sortedLessons.length,
            'courseProgressId': courseProgressId ?? '',
          },
          'lessonId': nextLesson.id,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more lessons available in this module.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrefetchingNextLesson = false;
        });
      }
    }
  }

  void _goToCourseDetail(BuildContext context, String? courseId) {
    bool isValidUuid = false;
    if (courseId != null) {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      isValidUuid = uuidRegex.hasMatch(courseId);
    }

    if (courseId != null && courseId.isNotEmpty && isValidUuid) {
      context.go('/course/$courseId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course ID not found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonFromSupabaseProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return _buildErrorScaffold('Lesson not found.');
        }

        final moduleId = lesson.moduleId;
        final moduleAsync = ref.watch(moduleFromSupabaseProvider(moduleId));

        return moduleAsync.when(
          data: (moduleData) {
            if (moduleData == null) {
              return _buildErrorScaffold('Module not found.');
            }

            final completedLessonIdsAsync =
                ref.watch(completedLessonIdsProvider(moduleId));

            return completedLessonIdsAsync.when(
              data: (completedLessonIds) {
                final sortedLessons = List<LessonModel>.of(moduleData.lessons)
                  ..sort((a, b) {
                    final positionCompare = a.position.compareTo(b.position);
                    if (positionCompare != 0) {
                      return positionCompare;
                    }
                    return a.id.compareTo(b.id);
                  });
                final resolvedLessonIndex = sortedLessons
                    .indexWhere((sortedLesson) => sortedLesson.id == lesson.id);
                final safeLessonIndex =
                    resolvedLessonIndex >= 0 ? resolvedLessonIndex : 0;
                final completedCount = sortedLessons
                    .where((sortedLesson) =>
                        completedLessonIds.contains(sortedLesson.id))
                    .length;
                final totalCount = sortedLessons.length;
                final isModuleComplete =
                    totalCount > 0 && completedCount == totalCount;
                final nextLesson = (!isModuleComplete &&
                        safeLessonIndex < sortedLessons.length - 1)
                    ? sortedLessons[safeLessonIndex + 1]
                    : null;

                final courseId = moduleData.module.courseId;
                final courseAsync = ref.watch(completeCourseProvider(courseId));

                return courseAsync.when(
                  data: (course) {
                    final currentModuleIndex = course.modules
                        .indexWhere((module) => module.module.id == moduleId);
                    final resolvedModuleIndex =
                        currentModuleIndex >= 0 ? currentModuleIndex : 0;
                    final totalModules = course.modules.length;
                    final totalLessons = course.modules
                        .fold(0, (sum, m) => sum + m.lessons.length);
                    final moduleTitle = moduleData.module.description;

                    return Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.help_outline,
                                color: Colors.black),
                            onPressed: () {},
                          ),
                        ],
                        centerTitle: true,
                        title: const SizedBox.shrink(),
                      ),
                      backgroundColor: const Color(0xFFF8F8F8),
                      body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Completed Lesson Card
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF232B3A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.successShadowColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 10),
                                    ),
                                    onPressed: () {
                                      final courseContext = <String, dynamic>{
                                        'courseId': courseId,
                                        'moduleId': moduleId,
                                        'currentLessonIndex': safeLessonIndex,
                                        'currentModuleIndex': resolvedModuleIndex,
                                        'moduleLessonsCount': totalCount,
                                        'courseTitle': course.course.title,
                                        'moduleTitle': moduleTitle,
                                        'totalModules': totalModules,
                                        'totalLessons': totalLessons,
                                      };
                                      if (lesson.id.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Unable to restart lesson.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      context.go(
                                        '/lesson/${lesson.id}',
                                        extra: {
                                          if (courseContext.isNotEmpty)
                                            'courseContext': courseContext,
                                          'lessonId': lesson.id,
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    label: const Text('Restart',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress
                            Center(
                              child: Text(
                                '$completedCount / $totalCount LESSONS',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Main Message
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  isModuleComplete
                                      ? 'You have completed this module'
                                      : 'You are almost there',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF232B3A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Upcoming lesson card (if nextLesson is available and not module complete)
                            if (!isModuleComplete && nextLesson != null)
                              Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (nextLesson.thumbnailUrl != null &&
                                        nextLesson.thumbnailUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          nextLesson.thumbnailUrl!,
                                          width: 110,
                                          height: 84,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: Colors.grey,
                                          size: 28,
                                        ),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Upcoming lesson',
                                            style: TextStyle(
                                                color: Colors.grey, fontSize: 15),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            nextLesson.title,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF232B3A),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${nextLesson.durationMinutes} Minutes',
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 20), // Bottom padding
                          ],
                        ),
                      ),
                      bottomNavigationBar: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isProcessing
                                    ? AppColors.primaryColor.withOpacity(0.8)
                                    : AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isModuleComplete
                                  ? _isProcessing
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isProcessing = true;
                                          });

                                          try {
                                            final userAsync = ref.read(authProvider);
                                            final userId = userAsync.asData?.value?.id;
                                            if (moduleId.isNotEmpty &&
                                                courseId.isNotEmpty &&
                                                userId != null) {
                                              setState(() {
                                                _progressMessage =
                                                    'Preparing module data...';
                                              });

                                              final courseProgressId = await ref
                                                  .read(getOrCreateCourseProgressProvider(courseId)
                                                      .future);
                                              debugPrint(
                                                  'CompleteLessonScreen: Using course progress ID: $courseProgressId');

                                              setState(() {
                                                _progressMessage =
                                                    'Saving module progress...';
                                              });

                                              final now = DateTime.now();
                                              final uuid = Uuid().v4();

                                              final moduleProgressModel =
                                                  ModuleProgressModel(
                                                id: uuid,
                                                userId: userId,
                                                moduleId: moduleId,
                                                courseProgressId: courseProgressId,
                                                status: 'completed',
                                                startedAt: null,
                                                completedAt: now,
                                                averageScore: 0.0,
                                                totalLessons: totalCount,
                                                completedLessons: completedCount,
                                                createdAt: now,
                                                updatedAt: now,
                                                needsSync: true,
                                              );
                                              await ref
                                                  .read(saveModuleProgressProvider(
                                                          moduleProgressModel)
                                                      .future);

                                              setState(() {
                                                _progressMessage =
                                                    'Updating course progress...';
                                              });

                                              final existingCourseProgress =
                                                  await ref.read(
                                                      courseProgressByIdProvider(
                                                              courseProgressId)
                                                          .future);
                                              if (existingCourseProgress != null) {
                                                final updatedCourseProgress =
                                                    CourseProgressModel(
                                                  id: existingCourseProgress.id,
                                                  userId: existingCourseProgress.userId,
                                                  courseId: existingCourseProgress.courseId,
                                                  startedAt:
                                                      existingCourseProgress.startedAt,
                                                  completedAt:
                                                      existingCourseProgress.completedAt,
                                                  currentModuleId: moduleId,
                                                  currentLessonId: lesson.id,
                                                  isCompleted:
                                                      existingCourseProgress.isCompleted,
                                                  createdAt:
                                                      existingCourseProgress.createdAt,
                                                  updatedAt: now,
                                                  needsSync: true,
                                                );
                                                await ref.read(
                                                    saveCourseProgressProvider(
                                                            updatedCourseProgress)
                                                        .future);
                                                debugPrint(
                                                    'CompleteLessonScreen: Updated existing course progress: ${existingCourseProgress.id}');
                                              } else {
                                                debugPrint(
                                                    'CompleteLessonScreen: Warning - Could not find existing course progress for ID: $courseProgressId');
                                              }

                                              setState(() {
                                                _progressMessage =
                                                    'Syncing with cloud...';
                                              });

                                              await ref
                                                  .read(syncAllProgressProvider.future);

                                              setState(() {
                                                _progressMessage =
                                                    'Checking course completion...';
                                              });

                                              await ref.read(
                                                  checkAndUpdateCourseCompletionProvider(
                                                          courseId)
                                                      .future);

                                              setState(() {
                                                _progressMessage =
                                                    'Updating interface...';
                                              });

                                              debugPrint(
                                                  'CompleteLessonScreen: Triggering comprehensive refresh for course $courseId');

                                              ref
                                                  .read(courseProgressRefreshProvider
                                                      .notifier)
                                                  .state++;
                                              await Future.delayed(
                                                  const Duration(milliseconds: 100));
                                              ref
                                                  .read(courseProgressRefreshProvider
                                                      .notifier)
                                                  .state++;

                                              await Future.delayed(
                                                  const Duration(milliseconds: 500));

                                              if (mounted) {
                                                setState(() {
                                                  _progressMessage =
                                                      'Success! Redirecting...';
                                                });

                                                await Future.delayed(
                                                    const Duration(milliseconds: 800));

                                                if (mounted) {
                                                  _goToCourseDetail(context, courseId);
                                                }
                                              }
                                            } else {
                                              debugPrint(
                                                  'CompleteLessonScreen: Error - Missing required data for module completion');
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                'Error processing module completion: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error saving progress: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _isProcessing = false;
                                                _progressMessage = '';
                                              });
                                            }
                                          }
                                        }
                                  : (_isPrefetchingNextLesson
                                      ? null
                                      : () => _goToNextLesson(
                                            context,
                                            course: course,
                                            currentModule: moduleData,
                                            sortedLessons: sortedLessons,
                                            currentLessonIndex: safeLessonIndex,
                                            completedLessonIds: completedLessonIds,
                                          )),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isProcessing || _isPrefetchingNextLesson) ...[
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      isModuleComplete ? 'Finish' : 'Next Lesson',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_right_alt,
                                        color: Colors.white, size: 24),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => _buildLoadingScaffold(),
                  error: (_, __) =>
                      _buildErrorScaffold('Error loading course.'),
                );
              },
              loading: () => _buildLoadingScaffold(),
              error: (_, __) =>
                  _buildErrorScaffold('Error loading lesson progress.'),
            );
          },
          loading: () => _buildLoadingScaffold(),
          error: (_, __) => _buildErrorScaffold('Error loading module.'),
        );
      },
      loading: () => _buildLoadingScaffold(),
      error: (_, __) => _buildErrorScaffold('Error loading lesson.'),
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScaffold(String message) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }
}
