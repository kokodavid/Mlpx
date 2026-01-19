import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/widgets/custom_button.dart';
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
                      backgroundColor: Colors.white,
                      body: SafeArea(
                        child: Column(
                          children: [
                            // Top Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                                    onPressed: () {
                                      if (courseId.isNotEmpty) {
                                        context.go('/course/$courseId');
                                      } else {
                                        context.pop();
                                      }
                                    },
                                  ),
                                  const Icon(Icons.help_outline_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Card: Lesson + Review Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    // Completion badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Review Lesson Button with Progress Indicator
                                    // Replace only the Review Lesson Button section (lines ~280-330) with this:

                                    Align(
                                      alignment: Alignment.center,
                                      child: FractionallySizedBox(
                                        widthFactor: 0.55,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                              context.go(
                                                '/lesson/${lesson.id}',
                                                extra: {
                                                  if (courseContext.isNotEmpty)
                                                    'courseContext': courseContext,
                                                  'lessonId': lesson.id,
                                                },
                                              );
                                            },
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Review Lesson',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Progress
                            Text(
                              '$completedCount of $totalCount LESSON${totalCount == 1 ? '' : 'S'}',
                              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isModuleComplete
                                  ? 'Module Complete!'
                                  : 'You are almost there',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 20),

                            // Next Lesson Button or Finish Button
                            if (isModuleComplete) ...[
                              if (_isProcessing) ...[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 8),
                                if (_progressMessage.isNotEmpty)
                                  Text(
                                    _progressMessage,
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                              ] else ...[
                                Align(
                                  alignment: Alignment.center,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.65,
                                    child: CustomButton(
                                      onPressed: () async {
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
                                              _progressMessage = 'Preparing module data...';
                                            });

                                            final courseProgressId = await ref
                                                .read(getOrCreateCourseProgressProvider(courseId)
                                                .future);

                                            setState(() {
                                              _progressMessage = 'Saving module progress...';
                                            });

                                            final now = DateTime.now();
                                            final uuid = Uuid().v4();

                                            final moduleProgressModel = ModuleProgressModel(
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
                                              _progressMessage = 'Updating course progress...';
                                            });

                                            final existingCourseProgress = await ref.read(
                                                courseProgressByIdProvider(courseProgressId)
                                                    .future);
                                            if (existingCourseProgress != null) {
                                              final updatedCourseProgress = CourseProgressModel(
                                                id: existingCourseProgress.id,
                                                userId: existingCourseProgress.userId,
                                                courseId: existingCourseProgress.courseId,
                                                startedAt: existingCourseProgress.startedAt,
                                                completedAt: existingCourseProgress.completedAt,
                                                currentModuleId: moduleId,
                                                currentLessonId: lesson.id,
                                                isCompleted: existingCourseProgress.isCompleted,
                                                createdAt: existingCourseProgress.createdAt,
                                                updatedAt: now,
                                                needsSync: true,
                                              );
                                              await ref.read(
                                                  saveCourseProgressProvider(updatedCourseProgress)
                                                      .future);
                                            }

                                            setState(() {
                                              _progressMessage = 'Syncing with cloud...';
                                            });

                                            await ref.read(syncAllProgressProvider.future);

                                            setState(() {
                                              _progressMessage = 'Checking course completion...';
                                            });

                                            await ref.read(
                                                checkAndUpdateCourseCompletionProvider(courseId)
                                                    .future);

                                            setState(() {
                                              _progressMessage = 'Updating interface...';
                                            });

                                            ref.read(courseProgressRefreshProvider.notifier).state++;
                                            await Future.delayed(const Duration(milliseconds: 100));
                                            ref.read(courseProgressRefreshProvider.notifier).state++;

                                            await Future.delayed(const Duration(milliseconds: 500));

                                            if (mounted) {
                                              setState(() {
                                                _progressMessage = 'Success! Redirecting...';
                                              });

                                              await Future.delayed(const Duration(milliseconds: 800));

                                              if (mounted) {
                                                _goToCourseDetail(context, courseId);
                                              }
                                            }
                                          }
                                        } catch (e) {
                                          debugPrint('Error processing module completion: $e');
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error saving progress: $e'),
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
                                      },
                                      text: 'Finish',
                                      textColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ] else if (nextLesson != null) ...[
                              Align(
                                alignment: Alignment.center,
                                child: FractionallySizedBox(
                                  widthFactor: 0.65,
                                  child: CustomButton(
                                    onPressed: _isPrefetchingNextLesson
                                        ? null
                                        : () => _goToNextLesson(
                                      context,
                                      course: course,
                                      currentModule: moduleData,
                                      sortedLessons: sortedLessons,
                                      currentLessonIndex: safeLessonIndex,
                                      completedLessonIds: completedLessonIds,
                                    ),
                                    text: _isPrefetchingNextLesson ? 'Loading...' : 'Next Lesson',
                                    textColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${nextLesson.durationMinutes} Minutes',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                            const Spacer(),

                            // Upcoming Lesson - Centered
                            if (nextLesson != null && !isModuleComplete)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Center(
                                  child: Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(maxWidth: 400),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7F7),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Upcoming lesson',
                                          style: TextStyle(color: Colors.black54),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          nextLesson.title,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${nextLesson.durationMinutes} Minutes',
                                          style: const TextStyle(color: Colors.black54),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => _buildLoadingScaffold(),
                  error: (_, __) => _buildErrorScaffold('Error loading course.'),
                );
              },
              loading: () => _buildLoadingScaffold(),
              error: (_, __) => _buildErrorScaffold('Error loading lesson progress.'),
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