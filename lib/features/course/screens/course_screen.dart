import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../course_widgets/course_card.dart';
import '../course_widgets/tab_button.dart';
import '../course_widgets/completed_course_card.dart';
import '../course_widgets/offline_courses_message.dart';
import '../providers/course_provider.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:milpress/providers/audio_service_provider.dart';

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen>
    with WidgetsBindingObserver {
  int selectedTab = 0;
  late FocusNode _focusNode;

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
    if (state == AppLifecycleState.resumed) {
      _refreshActiveCourseProgress();
    }
  }

  void _refreshActiveCourseProgress() {
    final activeCourse = ref.read(activeCourseWithDetailsProvider).value;
    if (activeCourse == null) {
      return;
    }
    final courseId = activeCourse.course.id;
    ref.invalidate(courseProgressV2Provider(courseId));
    ref.invalidate(completedModulesProvider(courseId));
    ref.invalidate(ongoingLessonInfoV2Provider(courseId));
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for reactivity
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    print("CourseScreen build - user: ${user?.id}, isGuest: ${authState.isGuestUser}");

    final activeCourseAsync = ref.watch(activeCourseWithDetailsProvider);
    print("activeCourseAsync: $activeCourseAsync");

    final upcomingCoursesAsync = ref.watch(upcomingCoursesWithDetailsProvider);
    print("upcomingCoursesAsync: $upcomingCoursesAsync");

    final completedCoursesAsync = ref.watch(completedCoursesWithDetailsProvider);
    print("completedCoursesAsync: $completedCoursesAsync");
    final userId = user?.id ?? 'guest_${authState.isGuestUser ? 'default' : 'unknown'}';

    // Show loading or error if not authenticated and not guest
    if (user == null && !authState.isGuestUser) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }


    // Build tab content
    Widget tabContent;
    if (selectedTab == 0) {
      // Active Tab
      final activeCourseAsync = ref.watch(activeCourseWithDetailsProvider);
      tabContent = activeCourseAsync.when(
        data: (courseWithDetails) {
          if (courseWithDetails == null) {
            return const Center(child: Text('No active course available'));
          }
          final course = courseWithDetails.course;
          final courseProgressAsync =
              ref.watch(courseProgressV2Provider(course.id));
          return courseProgressAsync.when(
            data: (progress) {
              final progressValue = progress.totalLessons > 0
                  ? progress.completedLessons / progress.totalLessons
                  : 0.0;
              return CourseCard(
                title: course.title,
                level: course.level,
                durationMinutes: course.durationInMinutes,
                totalModules: progress.totalModules,
                totalLessons: progress.totalLessons,
                eligible: true,
                locked: course.locked,
                isCompleted: progress.totalLessons > 0 &&
                    progress.completedLessons >= progress.totalLessons,
                completedLessons: progress.completedLessons,
                lessonProgressValue: progressValue,
                onStart: () async {
                  try {
                    final courseProgressId = await ref.read(
                        getOrCreateCourseProgressProvider(course.id).future);
                    context.push('/course/${course.id}', extra: {
                      'courseProgressId': courseProgressId,
                    });
                  } catch (e) {
                    context.push('/course/${course.id}');
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => OfflineCoursesMessage(
              onRetry: () {
                ref.invalidate(courseProgressV2Provider(course.id));
              },
            ),
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OfflineCoursesMessage(
          onRetry: () {
            ref.invalidate(activeCourseWithDetailsProvider);
          },
        ),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      );
    } else if (selectedTab == 1) {
      // Upcoming Tab
      final upcomingCoursesAsync = ref.watch(upcomingCoursesWithDetailsProvider);
      tabContent = upcomingCoursesAsync.when(
        data: (coursesWithDetails) {
          if (coursesWithDetails.isEmpty) {
            return const Center(child: Text('No upcoming courses'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = constraints.maxHeight * 0.85;
              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: coursesWithDetails.length,
                      controller: PageController(viewportFraction: 0.92),
                      itemBuilder: (context, index) {
                        final courseWithDetails = coursesWithDetails[index];
                        final course = courseWithDetails.course;
                        return Center(
                          child: SizedBox(
                            height: cardHeight,
                            width: 360,
                            child: CourseCard(
                              title: course.title,
                              level: course.level,
                              durationMinutes: course.durationInMinutes,
                              totalModules: courseWithDetails.totalModules,
                              totalLessons: courseWithDetails.totalLessons,
                              eligible: false,
                              locked: true,
                              isCompleted: false,
                              completedLessons: 0,
                              lessonProgressValue: 0.0,
                              lockMessage: 'Complete Level ${course.level - 1} to unlock',
                              onStart: null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(coursesWithDetails.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OfflineCoursesMessage(
          onRetry: () {
            ref.invalidate(upcomingCoursesWithDetailsProvider);
          },
        ),
      );
    } else {
      // Completed Tab
      final completedCoursesAsync = ref.watch(completedCoursesWithDetailsProvider);
      tabContent = completedCoursesAsync.when(
        data: (coursesWithDetails) {
          if (coursesWithDetails.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No completed courses yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Complete your first course to see it here', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: coursesWithDetails.length,
            itemBuilder: (context, index) {
              final courseWithDetails = coursesWithDetails[index];
              final course = courseWithDetails.course;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    try {
                      final courseProgressId = await ref.read(
                          getOrCreateCourseProgressProvider(course.id).future);
                      if (context.mounted) {
                        context.push('/course/${course.id}', extra: {
                          'courseProgressId': courseProgressId,
                          'isCompletedCourse': true,
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        context.push('/course/${course.id}', extra: {
                          'isCompletedCourse': true,
                        });
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('LEVEL ${course.level}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(course.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF232B3A))),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text('You have successfully completed this level', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view your progress and achievements',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OfflineCoursesMessage(
          onRetry: () {
            ref.invalidate(completedCoursesWithDetailsProvider);
          },
        ),
      );
    }

    // Return the Scaffold with tabs and content
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _refreshActiveCourseProgress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Course',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    TabButton(
                      label: 'Active',
                      selected: selectedTab == 0,
                      onTap: () => setState(() => selectedTab = 0),
                    ),
                    const SizedBox(width: 8),
                    TabButton(
                      label: 'Upcoming',
                      selected: selectedTab == 1,
                      onTap: () => setState(() => selectedTab = 1),
                    ),
                    const SizedBox(width: 8),
                    TabButton(
                      label: 'Completed',
                      selected: selectedTab == 2,
                      onTap: () => setState(() => selectedTab = 2),
                    ),
                  ],
                ),
              ),
              Expanded(child: tabContent),
            ],
          ),
        ),
      ),
    );
  }
}
