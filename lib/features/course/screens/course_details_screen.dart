import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/widgets/audio_play_button.dart';
import 'package:milpress/features/course/course_widgets/all_modules_widget.dart';
import 'package:milpress/features/course/course_widgets/course_progress_card.dart';
import 'package:milpress/features/course/course_widgets/description_section.dart';
import 'package:milpress/features/course/course_widgets/ongoing_module_card.dart';
import 'package:milpress/utils/app_colors.dart';
import '../providers/course_provider.dart';
import '../providers/module_provider.dart';
import '../course_models/complete_course_model.dart';
import '../course_widgets/course_detail_header.dart';
import 'package:milpress/features/lesson/lesson_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';

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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _checkAndRefreshCache();
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
      debugPrint('CourseDetailsScreen: didChangeDependencies called, refreshing progress providers for course ${widget.courseId}');
      
      // Check if cache needs refresh
      try {
        final box = await Hive.openBox<CompleteCourseModel>('complete_courses');
        final cachedCourse = box.get(widget.courseId);
        
        if (cachedCourse != null) {
          final cacheAge = DateTime.now().difference(cachedCourse.lastUpdated);
          final fiveMinutes = const Duration(minutes: 5);
          
          if (cacheAge > fiveMinutes) {
            // Cache is older than 5 minutes, refresh it
            debugPrint('Cache is ${cacheAge.inMinutes} minutes old, refreshing...');
            ref.invalidate(completeCourseProvider(widget.courseId));
          } else {
            debugPrint('Cache is fresh (${cacheAge.inMinutes} minutes old)');
          }
          
          // Verify quiz data is properly cached
          await ref.read(courseCacheProvider).verifyQuizData(widget.courseId);
        } else {
          debugPrint('No cached data found, will fetch fresh data');
        }
      } catch (e) {
        debugPrint('Error checking cache: $e');
      }
      
      // Refresh progress data
      _refreshProgressData();
    });
  }

  void _refreshProgressData() {
    debugPrint('CourseDetailsScreen: Refreshing all progress data for course ${widget.courseId}');
    
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
        final box = await Hive.openBox<CompleteCourseModel>('complete_courses');
        final course = box.get(widget.courseId);
        if (course != null) {
          for (final module in course.modules) {
            // Force refresh module quiz progress
            ref.read(moduleQuizProgressProvider(module.module.id).notifier).loadModuleProgress(module.module.id);
          }
        }
      } catch (e) {
        debugPrint('Error refreshing module progress: $e');
      }
    });
    
    debugPrint('CourseDetailsScreen: Progress providers refreshed');
  }

  Future<void> _checkAndRefreshCache() async {
    // Check if we have cached data and if it's older than 5 minutes
    try {
      final box = await Hive.openBox<CompleteCourseModel>('complete_courses');
      final cachedCourse = box.get(widget.courseId);
      
      if (cachedCourse != null) {
        final cacheAge = DateTime.now().difference(cachedCourse.lastUpdated);
        final fiveMinutes = const Duration(minutes: 5);
        
        if (cacheAge > fiveMinutes) {
          // Cache is older than 5 minutes, refresh it
          debugPrint('Cache is ${cacheAge.inMinutes} minutes old, refreshing...');
          // Don't invalidate provider here - do it in didChangeDependencies
        } else {
          debugPrint('Cache is fresh (${cacheAge.inMinutes} minutes old)');
        }
        
        // Don't verify quiz data here - do it in didChangeDependencies
      } else {
        debugPrint('No cached data found, will fetch fresh data');
      }
    } catch (e) {
      debugPrint('Error checking cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a completed course from navigation context
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isCompletedCourse = extra?['isCompletedCourse'] as bool? ?? false;
    
    final completeCourseAsync =
        ref.watch(completeCourseProvider(widget.courseId));
    final ongoingModuleAsync = ref.watch(ongoingModuleProvider(widget.courseId));
    final courseProgressAsync = ref.watch(courseProgressProvider(widget.courseId));
    final completedModulesAsync = ref.watch(completedModulesProvider(widget.courseId));
    final courseCompletedLessonsAsync = ref.watch(courseCompletedLessonsProvider(widget.courseId));
    final courseCompletedModulesAsync = ref.watch(courseCompletedModulesProvider(widget.courseId));
    
    // Watch the auto-refresh provider to ensure data is always fresh
    ref.watch(autoRefreshCourseDataProvider(widget.courseId));
    
    // Watch the stream-based refresh for immediate updates
    ref.watch(courseProgressRefreshStreamProvider(widget.courseId));

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          debugPrint('CourseDetailsScreen: Screen gained focus, refreshing progress data');
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
                        totalLessons: completeCourse.modules
                            .fold(0, (sum, m) => sum + m.lessons.length),
                      ),
                      const SizedBox(height: 24),
                      
                      // Completion banner for completed courses
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
                                      'Congratulations! You have successfully completed Level ${completeCourse.course.level}',
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
                        data: (completedLessons) => courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: completedLessons,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: completedLessons,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: completedLessons,
                            completedModules: 0,
                          ),
                        ),
                        loading: () => courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                        ),
                        error: (_, __) => courseCompletedModulesAsync.when(
                          data: (completedModules) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: completedModules,
                          ),
                          loading: () => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                          error: (_, __) => CourseProgressCard(
                            totalModules: completeCourse.modules.length,
                            totalLessons: completeCourse.modules
                                .fold(0, (sum, m) => sum + m.lessons.length),
                            completedLessons: 0,
                            completedModules: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Only show ongoing module for non-completed courses
                      if (!isCompletedCourse) ...[
                        ongoingModuleAsync.when(
                          data: (ongoingModule) {
                            if (ongoingModule != null) {
                              return Column(
                                children: [
                                  OngoingModuleCard(
                                    icon: Icons.menu_book,
                                    iconBgColor: AppColors.primaryColor,
                                    title: ongoingModule.module.description,
                                    subtitle: '${ongoingModule.lessons.length} Lessons',
                                    onTap: () async {
                                      if (ongoingModule.lessons.isNotEmpty) {
                                        final module = ongoingModule;
                                        final firstLesson = module.lessons.first;

                                        // Debug logging to verify quiz data is cached
                                        debugPrint('\n=== Ongoing Module Card Debug ===');
                                        debugPrint('Module: ${module.module.description}');
                                        debugPrint('Total lessons in module: ${module.lessons.length}');
                                        debugPrint('First lesson: ${firstLesson.title}');
                                        debugPrint('First lesson quizzes: ${firstLesson.quizzes.length}');
                                        
                                        // Log quiz details for the first lesson
                                        for (int i = 0; i < firstLesson.quizzes.length; i++) {
                                          final quiz = firstLesson.quizzes[i];
                                          debugPrint('Quiz $i:');
                                          debugPrint('  - Stage: ${quiz.stage}');
                                          debugPrint('  - Question Type: ${quiz.questionType}');
                                          debugPrint('  - Has Audio: ${quiz.soundFileUrl != null && quiz.soundFileUrl!.isNotEmpty}');
                                          debugPrint('  - Options: ${quiz.options.length}');
                                        }
                                        
                                        // Check all lessons in the module for quizzes
                                        int totalQuizzes = 0;
                                        for (final lesson in module.lessons) {
                                          totalQuizzes += lesson.quizzes.length;
                                        }
                                        debugPrint('Total quizzes in module: $totalQuizzes');
                                        debugPrint('=====================================\n');

                                        // Pre-fetch module data to ensure it's available
                                        await ref.read(
                                            moduleFromHiveProvider(module.module.id).future);

                                        // Look up courseProgressId for this user and course
                                        String? courseProgressId;
                                        final user = SupabaseConfig.currentUser;
                                        final userId = user?.id;
                                        if (userId != null) {
                                          final box = await Hive.openBox<CourseProgressModel>('course_progress');
                                          try {
                                            final existing = box.values.cast<CourseProgressModel>().firstWhere(
                                              (cp) => cp.userId == userId && cp.courseId == completeCourse.course.id,
                                            );
                                            courseProgressId = existing.id;
                                          } catch (_) {
                                            courseProgressId = null;
                                          }
                                        }

                                        // Navigate to the lesson with course context
                                        if (context.mounted) {
                                          context.push('/lesson/${firstLesson.id}', extra: {
                                            'courseContext': {
                                              'courseId': completeCourse.course.id,
                                              'courseTitle': completeCourse.course.title,
                                              'moduleId': module.module.id,
                                              'moduleTitle': module.module.description,
                                              'totalModules': completeCourse.modules.length,
                                              'totalLessons': completeCourse.modules
                                                  .fold(0, (sum, m) => sum + m.lessons.length),
                                              'currentLessonIndex': module.lessons.indexOf(firstLesson),
                                              'currentModuleIndex': completeCourse.modules.indexOf(module),
                                              'moduleLessonsCount': module.lessons.length,
                                              'courseProgressId': courseProgressId ?? '',
                                            },
                                          });
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                      
                      // Review button for completed courses
                      if (isCompletedCourse) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              // Show a dialog with options to review the course
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Review Course'),
                                    content: const Text(
                                      'Choose how you would like to review this completed course:',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          // Navigate to first lesson for review
                                          if (completeCourse.modules.isNotEmpty && 
                                              completeCourse.modules.first.lessons.isNotEmpty) {
                                            final firstModule = completeCourse.modules.first;
                                            final firstLesson = firstModule.lessons.first;
                                            
                                            context.push('/lesson/${firstLesson.id}', extra: {
                                              'courseContext': {
                                                'courseId': completeCourse.course.id,
                                                'courseTitle': completeCourse.course.title,
                                                'moduleId': firstModule.module.id,
                                                'moduleTitle': firstModule.module.description,
                                                'totalModules': completeCourse.modules.length,
                                                'totalLessons': completeCourse.modules
                                                    .fold(0, (sum, m) => sum + m.lessons.length),
                                                'currentLessonIndex': 0,
                                                'currentModuleIndex': 0,
                                                'moduleLessonsCount': firstModule.lessons.length,
                                                'isReviewMode': true,
                                              },
                                            });
                                          }
                                        },
                                        child: const Text('Start from Beginning'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          // Stay on current screen to view all modules
                                        },
                                        child: const Text('View All Modules'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.refresh, size: 20),
                            label: const Text(
                              'Review Course',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      DescriptionSection(
                          courseTitle: completeCourse.course.title,
                          level: completeCourse.course.level,
                          totalModules: completeCourse.modules.length,
                          totalLessons: completeCourse.modules
                              .fold(0, (sum, m) => sum + m.lessons.length),
                          description: completeCourse.course.description),
                      const SizedBox(height: 24),
                      completedModulesAsync.when(
                        data: (completedModules) => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: completedModules,
                          ongoingModuleId: ongoingModuleAsync.value?.module.id,
                        ),
                        loading: () => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: {},
                          ongoingModuleId: null,
                        ),
                        error: (_, __) => AllModulesWidget(
                          modules: completeCourse.modules,
                          completedModules: {},
                          ongoingModuleId: null,
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
