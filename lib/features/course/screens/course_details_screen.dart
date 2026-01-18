import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/widgets/audio_play_button.dart';
import 'package:milpress/features/course/course_widgets/all_modules_widget.dart';
import 'package:milpress/features/course/course_widgets/course_progress_card.dart';
import 'package:milpress/features/course/course_widgets/ongoing_module_card.dart';
import 'package:milpress/utils/app_colors.dart';
import '../course_models/complete_course_model.dart';
import '../providers/course_provider.dart';
import '../providers/module_provider.dart';
import '../course_widgets/course_detail_header.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart'
    as lessons_v2;
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen>
    with WidgetsBindingObserver {
  late FocusNode _focusNode;
  bool _isOngoingModuleLoading = false;
  ModuleWithLessons? _cachedOngoingModule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes active (user returns from background)
    if (state == AppLifecycleState.resumed) {
      debugPrint('CourseDetailsScreen: App resumed, refreshing progress data');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Trigger refresh provider instead of calling _refreshProgressData directly
        ref.read(courseProgressRefreshProvider.notifier).state++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh progress providers when screen is focused (e.g., returning from lesson completion)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint(
          'CourseDetailsScreen: didChangeDependencies called, refreshing progress providers for course ${widget.courseId}');

      // Refresh progress data
      _refreshProgressData();
    });
  }

  void _refreshProgressData() {
    debugPrint(
        'CourseDetailsScreen: Refreshing all progress data for course ${widget.courseId}');
    if (mounted && _isOngoingModuleLoading) {
      setState(() {
        _isOngoingModuleLoading = false;
      });
    }

    // Invalidate all relevant providers
    ref.invalidate(courseCompletedLessonsProvider(widget.courseId));
    ref.invalidate(courseCompletedModulesProvider(widget.courseId));
    ref.invalidate(completedModulesProvider(widget.courseId));
    ref.invalidate(ongoingModuleProvider(widget.courseId));
    ref.invalidate(courseProgressProvider(widget.courseId));

    // Trigger the refresh provider to update all progress data
    ref.read(courseProgressRefreshProvider.notifier).state++;

    // Ensure all module progress providers are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final course =
            await ref.read(completeCourseProvider(widget.courseId).future);
        for (final module in course.modules) {
          // Force refresh module quiz progress
          ref
              .read(moduleQuizProgressProvider(module.module.id).notifier)
              .loadModuleProgress(module.module.id);
        }
      } catch (e) {
        debugPrint('Error refreshing module progress: $e');
      }
    });

    debugPrint('CourseDetailsScreen: Progress providers refreshed');
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a completed course from navigation context
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isCompletedCourse = extra?['isCompletedCourse'] as bool? ?? false;

    final completeCourseAsync =
        ref.watch(completeCourseProvider(widget.courseId));
    final ongoingModuleAsync =
        ref.watch(ongoingModuleProvider(widget.courseId));
    final courseProgressAsync =
        ref.watch(courseProgressProvider(widget.courseId));
    final completedModulesAsync =
        ref.watch(completedModulesProvider(widget.courseId));
    final courseCompletedLessonsAsync =
        ref.watch(courseCompletedLessonsProvider(widget.courseId));
    final courseCompletedModulesAsync =
        ref.watch(courseCompletedModulesProvider(widget.courseId));

    // Watch the auto-refresh provider to ensure data is always fresh
    ref.watch(autoRefreshCourseDataProvider(widget.courseId));

    // Watch the stream-based refresh for immediate updates
    ref.watch(courseProgressRefreshStreamProvider(widget.courseId));
    ref.listen<AsyncValue<ModuleWithLessons?>>(
      ongoingModuleProvider(widget.courseId),
      (previous, next) {
        next.whenData((module) {
          if (!mounted || module == null) {
            return;
          }
          final cached = _cachedOngoingModule;
          final hasChanged = cached == null ||
              cached.module.id != module.module.id ||
              cached.lessons.length != module.lessons.length;
          if (hasChanged) {
            setState(() {
              _cachedOngoingModule = module;
            });
          }
        });
      },
    );

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          debugPrint(
              'CourseDetailsScreen: Screen gained focus, refreshing progress data');
          // Trigger refresh provider instead of calling _refreshProgressData directly
          ref.read(courseProgressRefreshProvider.notifier).state++;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.sandyLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: AudioPlayButton(
                screenId: 'course_details_screen',
                lottieAsset: 'assets/waveworm.json',
                audioStoragePath: 'course_detail.mp3',
                backgroundColor: AppColors.successColor,
                height: 32,
              ),
            ),
          ],
          centerTitle: true,
          title: const SizedBox.shrink(),
        ),
        body: completeCourseAsync.when(
          data: (completeCourse) {
            final totalModules = completeCourse.modules.length;
            final totalLessons = completeCourse.modules
                .fold<int>(0, (sum, m) => sum + m.lessons.length);
            final allModulesCompleted = completedModulesAsync.maybeWhen(
              data: (completedModules) =>
                  totalModules > 0 &&
                  completedModules.values
                          .where((completed) => completed)
                          .length >=
                      totalModules,
              orElse: () => false,
            );
            return RefreshIndicator(
              onRefresh: () async {
                // Force refresh the course data
                ref.invalidate(completeCourseProvider(widget.courseId));
                // Force refresh all progress providers
                ref.invalidate(courseCompletedLessonsProvider(widget.courseId));
                ref.invalidate(courseCompletedModulesProvider(widget.courseId));
                ref.invalidate(completedModulesProvider(widget.courseId));
                ref.invalidate(ongoingModuleProvider(widget.courseId));
                // Trigger the refresh provider to update all progress data
                ref.read(courseProgressRefreshProvider.notifier).state++;
              },
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CourseDetailHeader(
                        courseTitle: completeCourse.course.title,
                        level: completeCourse.course.level,
                        totalModules: completeCourse.modules.length,
                        totalLessons: totalLessons,
                      ),
                      const SizedBox(
                          height:
                              24), // Completion banner for completed courses
                      if (isCompletedCourse)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Course Completed! 🎉',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Congratulations! You have successfully completed ${completeCourse.course.title}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      courseCompletedLessonsAsync.when(
                        data: (completedLessons) =>
                            courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: completedLessons,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: completedLessons,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: completedLessons,
                            completedModules: 0,
                          ),
                        ),
                        loading: () => courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                        ),
                        error: (_, __) => courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: totalLessons,
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Only show ongoing module for non-completed courses
                      if (!isCompletedCourse) ...[
                        Builder(builder: (context) {
                          if (allModulesCompleted) {
                            return Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 22, horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 32),
                                      SizedBox(height: 10),
                                      Text(
                                        'All modules completed',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF232B3A),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'You have completed this course.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          final ongoingModule =
                              ongoingModuleAsync.value ?? _cachedOngoingModule;
                          if (ongoingModule == null) {
                            return const SizedBox.shrink();
                          }
                          final moduleLessonsAsync = ref.watch(
                            lessons_v2.moduleLessonsProvider(
                              ongoingModule.module.id,
                            ),
                          );
                          final moduleLessons =
                              moduleLessonsAsync.value ??
                                  const <LessonDefinition>[];
                          final nextLessonForCard = moduleLessons.isNotEmpty
                              ? moduleLessons.first
                              : null;
                          final isLessonsLoading =
                              moduleLessonsAsync.isLoading &&
                                  moduleLessons.isEmpty;
                          return Column(
                            children: [
                              OngoingModuleCard(
                                icon: Icons.menu_book,
                                iconBgColor: AppColors.primaryColor,
                                title: ongoingModule.module.description,
                                lessonTitle: isLessonsLoading
                                    ? 'Loading lesson...'
                                    : (nextLessonForCard?.title ?? ''),
                                subtitle:
                                    isLessonsLoading
                                        ? 'Loading lessons...'
                                        : '${moduleLessons.length} Lessons',
                                isLoading: _isOngoingModuleLoading ||
                                    isLessonsLoading,
                                onTap: () async {
                                  if (_isOngoingModuleLoading) {
                                    return;
                                  }
                                  setState(() {
                                    _isOngoingModuleLoading = true;
                                  });
                                  try {
                                    var nextLesson = nextLessonForCard;
                                    if (nextLesson == null) {
                                      final fetchedLessons = await ref.read(
                                        lessons_v2.moduleLessonsProvider(
                                          ongoingModule.module.id,
                                        ).future,
                                      );
                                      if (fetchedLessons.isNotEmpty) {
                                        nextLesson = fetchedLessons.first;
                                      }
                                    }
                                    if (nextLesson == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'No lessons available yet.'),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    if (context.mounted) {
                                      await context.push(
                                        '/lesson-attempt',
                                        extra: {
                                          'lessonId': nextLesson.id,
                                        },
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isOngoingModuleLoading = false;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                      ],

                      const SizedBox(height: 24),
                      completedModulesAsync.when(
                        data: (completedModules) => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: completedModules,
                          ongoingModuleId: allModulesCompleted
                              ? null
                              : ongoingModuleAsync.value?.module.id,
                          courseId: completeCourse.course.id,
                          courseTitle: completeCourse.course.title,
                          totalModules: totalModules,
                          totalLessons: totalLessons,
                        ),
                        loading: () => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: {},
                          ongoingModuleId: null,
                          courseId: completeCourse.course.id,
                          courseTitle: completeCourse.course.title,
                          totalModules: totalModules,
                          totalLessons: totalLessons,
                        ),
                        error: (_, __) => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: {},
                          ongoingModuleId: null,
                          courseId: completeCourse.course.id,
                          courseTitle: completeCourse.course.title,
                          totalModules: totalModules,
                          totalLessons: totalLessons,
                        ),
                      ),
                      // ...add more widgets for progress, ongoing lesson, etc.
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error loading course: $error'),
          ),
        ),
      ),
    );
  }
}
