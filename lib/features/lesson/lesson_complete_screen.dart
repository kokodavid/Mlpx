import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/lesson/providers/lesson_quiz_progress_provider.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:milpress/features/user_progress/models/module_progress_model.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';

class LessonCompleteScreen extends ConsumerStatefulWidget {
  final String lessonTitle;
  final bool isLastLesson;
  final int completedCount;
  final int totalCount;
  final String? nextLessonTitle;
  final int? nextLessonDuration;
  final String? nextLessonId;
  final List<Map<String, dynamic>>? upcomingLessons;
  final String? courseId;
  final Map<String, dynamic>? quizResult;

  const LessonCompleteScreen({
    Key? key,
    required this.lessonTitle,
    required this.isLastLesson,
    required this.completedCount,
    required this.totalCount,
    this.nextLessonTitle,
    this.nextLessonDuration,
    this.nextLessonId,
    this.upcomingLessons,
    this.courseId,
    this.quizResult,
  }) : super(key: key);

  @override
  ConsumerState<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends ConsumerState<LessonCompleteScreen> {
  bool _isProcessing = false;
  String _progressMessage = '';
  bool _isPrefetchingNextLesson = false;
  
  @override
  void initState() {
    super.initState();
    // Handle quiz result if provided
    if (widget.quizResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final score = widget.quizResult!['score'] as int;
        ref.read(lessonQuizProgressProvider.notifier).markCompleted(score);
      });
    }
  }

  Future<void> _goToNextLesson(BuildContext context) async {
    if (_isPrefetchingNextLesson) {
      return;
    }
    setState(() {
      _isPrefetchingNextLesson = true;
    });
    // Get the extra data passed from the lesson screen
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final courseId = extra?['courseId'] as String?;
    final moduleId = extra?['moduleId'] as String?;
    final currentLessonIndex = extra?['currentLessonIndex'] as int? ?? 0;
    final currentModuleIndex = extra?['currentModuleIndex'] as int? ?? 0;
    final currentLessonId = extra?['lessonId'] as String?;
    
    if (courseId == null || moduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find next lesson.')),
      );
      if (mounted) {
        setState(() {
          _isPrefetchingNextLesson = false;
        });
      }
      return;
    }

    // Only allow navigation within the first module (index 0)
    // if (currentModuleIndex > 0) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please complete the first module first.'),
    //       backgroundColor: Colors.orange,
    //     ),
    //   );
    //   return;
    // }

    try {
      final courseService = ref.read(courseServiceProvider);
      final course = await courseService.getCompleteCourse(courseId);

      // Find the current module (should be the first module)
      final currentModule = course.modules.firstWhere(
        (module) => module.module.id == moduleId,
        orElse: () => throw Exception('Module not found: $moduleId'),
      );
      final sortedLessons = List.of(currentModule.lessons)
        ..sort((a, b) {
          final positionCompare = a.position.compareTo(b.position);
          if (positionCompare != 0) {
            return positionCompare;
          }
          return a.id.compareTo(b.id);
        });
      final resolvedLessonIndex = currentLessonId == null
          ? currentLessonIndex
          : sortedLessons.indexWhere((lesson) => lesson.id == currentLessonId);
      final safeLessonIndex = resolvedLessonIndex >= 0 ? resolvedLessonIndex : currentLessonIndex;
      debugPrint('LessonCompleteScreen: module ${currentModule.module.id} has ${sortedLessons.length} lessons');
      debugPrint('LessonCompleteScreen: currentLessonIndex=$currentLessonIndex currentLessonId=$currentLessonId resolvedLessonIndex=$safeLessonIndex');
      for (var i = 0; i < sortedLessons.length; i++) {
        final lesson = sortedLessons[i];
        debugPrint('LessonCompleteScreen: lesson[$i] id=${lesson.id} position=${lesson.position} title=${lesson.title}');
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
      if (safeLessonIndex < sortedLessons.length - 1) {
        // Next lesson in the same module
        final nextLesson = sortedLessons[safeLessonIndex + 1];
        debugPrint('LessonCompleteScreen: nextLessonIndex=${safeLessonIndex + 1} nextLessonId=${nextLesson.id}');

        try {
          await ref.read(
            lessonFromSupabaseProvider(nextLesson.id).future,
          );
        } catch (e) {
          debugPrint('LessonCompleteScreen: error prefetching next lesson: $e');
        }

        context.pushReplacement('/lesson/${nextLesson.id}', extra: {
          'courseContext': {
            'courseId': courseId,
            'courseTitle': course.course.title,
            'moduleId': moduleId,
            'moduleTitle': currentModule.module.description,
            'totalModules': course.modules.length,
            'totalLessons': course.modules.fold(0, (sum, m) => sum + m.lessons.length),
            'currentLessonIndex': safeLessonIndex + 1,
            'currentModuleIndex': currentModuleIndex,
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

  void _goToCourseDetail(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final courseId = extra?['courseId'] as String?;
   

    // Validate course ID format (should be a UUID)
    bool isValidUuid = false;
    if (courseId != null) {
      // Simple UUID validation (8-4-4-4-12 format)
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      isValidUuid = uuidRegex.hasMatch(courseId);
    }
    
    if (courseId != null && courseId.isNotEmpty && isValidUuid) {
      // Use go() to clear the navigation stack and navigate to course detail
      // This prevents multiple course detail screens from being stacked
      context.go('/course/$courseId');
    } else {
      if (widget.courseId != null && widget.courseId!.isNotEmpty) {
        final widgetCourseIdValid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(widget.courseId!);
        if (widgetCourseIdValid) {
          context.go('/course/${widget.courseId}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid course ID.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course ID not found.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the extra data passed from the lesson screen
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final courseId = extra?['courseId'] as String?;
    final moduleId = extra?['moduleId'] as String?;
    final currentLessonIndex = extra?['currentLessonIndex'] as int? ?? 0;
    final currentModuleIndex = extra?['currentModuleIndex'] as int? ?? 0;
    final currentLessonId = extra?['lessonId'] as String?;
    final isModuleComplete = extra?['isModuleComplete'] as bool? ?? false;
    
    // Determine next lesson info (only show if not module complete)
    String? nextLessonTitle;
    String? nextLessonId;
    String? nextLessonThumbnail;
    int? nextLessonMinutes;
    
    if (!isModuleComplete && courseId != null && moduleId != null) {
      final completeCourse = ref
          .watch(completeCourseProvider(courseId))
          .maybeWhen(data: (course) => course, orElse: () => null);

      if (completeCourse != null) {
        final currentModule = completeCourse.modules.firstWhere(
          (module) => module.module.id == moduleId,
          orElse: () => completeCourse.modules.first,
        );
        final sortedLessons = List.of(currentModule.lessons)
          ..sort((a, b) {
            final positionCompare = a.position.compareTo(b.position);
            if (positionCompare != 0) {
              return positionCompare;
            }
            return a.id.compareTo(b.id);
          });
        final resolvedLessonIndex = currentLessonId == null
            ? currentLessonIndex
            : sortedLessons.indexWhere((lesson) => lesson.id == currentLessonId);
        final safeLessonIndex = resolvedLessonIndex >= 0 ? resolvedLessonIndex : currentLessonIndex;

        // Check if there's a next lesson in the current module
        if (safeLessonIndex < sortedLessons.length - 1) {
          final nextLesson = sortedLessons[safeLessonIndex + 1];
          nextLessonTitle = nextLesson.title;
          nextLessonId = nextLesson.id;
          nextLessonThumbnail = nextLesson.thumbnailUrl;
          nextLessonMinutes = nextLesson.durationMinutes;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    widget.lessonTitle,
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
                      backgroundColor: AppColors.successShadowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    onPressed: () {
                      final extra = GoRouterState.of(context).extra
                          as Map<String, dynamic>?;
                      final lessonId = extra?['lessonId'] as String?;
                      final courseId = extra?['courseId'] as String?;
                      final moduleId = extra?['moduleId'] as String?;
                      final courseProgressId = extra?['courseProgressId'] as String?;
                      final courseContext = <String, dynamic>{
                        if (courseId != null) 'courseId': courseId,
                        if (moduleId != null) 'moduleId': moduleId,
                        if (courseProgressId != null) 'courseProgressId': courseProgressId,
                        if (extra?['currentLessonIndex'] != null)
                          'currentLessonIndex': extra?['currentLessonIndex'],
                        if (extra?['currentModuleIndex'] != null)
                          'currentModuleIndex': extra?['currentModuleIndex'],
                        if (extra?['moduleLessonsCount'] != null)
                          'moduleLessonsCount': extra?['moduleLessonsCount'],
                        if (extra?['courseTitle'] != null)
                          'courseTitle': extra?['courseTitle'],
                        if (extra?['moduleTitle'] != null)
                          'moduleTitle': extra?['moduleTitle'],
                        if (extra?['totalModules'] != null)
                          'totalModules': extra?['totalModules'],
                        if (extra?['totalLessons'] != null)
                          'totalLessons': extra?['totalLessons'],
                      };
                      if (lessonId == null || lessonId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to restart lesson.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ref.read(lessonQuizProgressProvider.notifier).reset();
                      context.go(
                        '/lesson/$lessonId',
                        extra: {
                          if (courseContext.isNotEmpty) 'courseContext': courseContext,
                          'lessonId': lessonId,
                        },
                      );
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Restart',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Progress
            Center(
              child: Text(
                '${widget.completedCount} / ${widget.totalCount} LESSONS',
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            // Module Progress Summary (only show when module is complete)
            if (isModuleComplete && moduleId != null)
              Consumer(
                builder: (context, ref, child) {
                  final moduleProgress = ref.watch(moduleQuizProgressProvider(moduleId));
                  
                  if (moduleProgress != null && moduleProgress.lessonScores.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.assessment,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Module Progress Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...moduleProgress.lessonScores.entries.map((entry) {
                            final lessonId = entry.key;
                            final lessonScore = entry.value;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lessonScore.lessonTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF232B3A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        lessonScore.isCompleted 
                                            ? Icons.check_circle 
                                            : Icons.circle_outlined,
                                        size: 16,
                                        color: lessonScore.isCompleted 
                                            ? Colors.green 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Score: ${lessonScore.score}/${lessonScore.totalQuestions}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: lessonScore.isCompleted 
                                                ? Colors.green 
                                                : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (lessonScore.isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Completed',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (lessonScore.completedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Completed: ${_formatDate(lessonScore.completedAt!)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Average Score: ${moduleProgress.averageScore.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            const SizedBox(height: 18),
            // Upcoming lesson card (if nextLesson is available and not module complete)
            if (!isModuleComplete && nextLessonTitle != null)
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
                    if (nextLessonThumbnail != null &&
                        nextLessonThumbnail!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          nextLessonThumbnail!,
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
                          borderRadius: BorderRadius.circular(12),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming lesson',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextLessonTitle!,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${nextLessonMinutes ?? widget.nextLessonDuration ?? 0} Minutes',
                              style:
                                  const TextStyle(color: Colors.grey, fontSize: 15),
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
                      ? null // Disable button when processing
                      : () async {
                          setState(() {
                            _isProcessing = true;
                          });
                          
                          try {
                            // Gather module progress data
                            final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
                            final moduleId = extra?['moduleId'] as String?;
                            final courseId = extra?['courseId'] as String?;
                            final moduleProgress = moduleId != null ? ref.read(moduleQuizProgressProvider(moduleId)) : null;
                            final userAsync = ref.read(authProvider);
                            final userId = userAsync.asData?.value?.id;
                            if (moduleId != null && courseId != null && moduleProgress != null && userId != null) {
                              
                              // Update progress message
                              setState(() {
                                _progressMessage = 'Preparing module data...';
                              });
                              
                              // Use course progress service to get or create course progress
                              final courseProgressId = await ref.read(getOrCreateCourseProgressProvider(courseId).future);
                              debugPrint('LessonCompleteScreen: Using course progress ID: $courseProgressId');
                              
                              setState(() {
                                _progressMessage = 'Saving module progress...';
                              });
                              
                              final now = DateTime.now();
                              final uuid = Uuid().v4();
                              
                              // Create module progress with correct courseProgressId
                              final moduleProgressModel = ModuleProgressModel(
                                id: uuid,
                                userId: userId,
                                moduleId: moduleId,
                                courseProgressId: courseProgressId, // Use the service-provided ID
                                status: 'completed',
                                startedAt: null, // Fill if you track module start
                                completedAt: now,
                                averageScore: moduleProgress.averageScore,
                                totalLessons: moduleProgress.lessonScores.length,
                                completedLessons: moduleProgress.lessonScores.values.where((s) => s.isCompleted).length,
                                createdAt: now,
                                updatedAt: now,
                                needsSync: true,
                              );
                              await ref.read(saveModuleProgressProvider(moduleProgressModel).future);
                              
                              setState(() {
                                _progressMessage = 'Updating course progress...';
                              });
                              
                              // Update existing course progress instead of creating new one
                              final existingCourseProgress = await ref.read(courseProgressByIdProvider(courseProgressId).future);
                              if (existingCourseProgress != null) {
                                final lastLessonId = extra?['lessonId'] as String? ?? nextLessonId ?? '';
                                final updatedCourseProgress = CourseProgressModel(
                                  id: existingCourseProgress.id, // Keep existing ID
                                  userId: existingCourseProgress.userId,
                                  courseId: existingCourseProgress.courseId,
                                  startedAt: existingCourseProgress.startedAt,
                                  completedAt: existingCourseProgress.completedAt,
                                  currentModuleId: moduleId,
                                  currentLessonId: lastLessonId,
                                  isCompleted: existingCourseProgress.isCompleted, // Don't mark course as completed yet
                                  createdAt: existingCourseProgress.createdAt,
                                  updatedAt: now,
                                  needsSync: true,
                                );
                                await ref.read(saveCourseProgressProvider(updatedCourseProgress).future);
                                debugPrint('LessonCompleteScreen: Updated existing course progress: ${existingCourseProgress.id}');
                              } else {
                                debugPrint('LessonCompleteScreen: Warning - Could not find existing course progress for ID: $courseProgressId');
                              }
                              
                              setState(() {
                                _progressMessage = 'Syncing with cloud...';
                              });
                              
                              await ref.read(syncAllProgressProvider.future);
                              
                              setState(() {
                                _progressMessage = 'Checking course completion...';
                              });
                              
                              // Check if course is now completed
                              if (courseId != null) {
                                await ref.read(checkAndUpdateCourseCompletionProvider(courseId).future);
                              }
                              
                              setState(() {
                                _progressMessage = 'Updating interface...';
                              });
                              
                              // Trigger multiple refresh mechanisms for reliability
                              debugPrint('LessonCompleteScreen: Triggering comprehensive refresh for course $courseId');
                              
                              // Trigger the refresh provider multiple times to ensure update
                              ref.read(courseProgressRefreshProvider.notifier).state++;
                              await Future.delayed(const Duration(milliseconds: 100));
                              ref.read(courseProgressRefreshProvider.notifier).state++;
                              
                              // Add a small delay to ensure all data is saved before navigation
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              if (mounted) {
                                setState(() {
                                  _progressMessage = 'Success! Redirecting...';
                                });
                                
                                // Brief success message before navigation
                                await Future.delayed(const Duration(milliseconds: 800));
                                
                                if (mounted) {
                                  _goToCourseDetail(context);
                                }
                              }
                            } else {
                              debugPrint('LessonCompleteScreen: Error - Missing required data for module completion');
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
                        }
                  : (_isPrefetchingNextLesson ? null : () => _goToNextLesson(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing || _isPrefetchingNextLesson) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
