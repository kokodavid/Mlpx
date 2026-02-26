import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../providers/auth_provider.dart';
import '../course/providers/course_provider.dart';
import '../profile/providers/profile_provider.dart';
import 'home_course_tile.dart';
import 'home_header.dart';
import 'home_sub_course_tile.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  int _selectedIndex = 0;
  bool _hasScrolledToActive = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openCourse(String courseId) async {
    if (!mounted) return;
    context.push('/course/$courseId');
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      default:
        return 'Level $level';
    }
  }

  bool _isEligibleCourse({
    required int selectedLevel,
    required int? activeLevel,
  }) {
    if (activeLevel == null) return selectedLevel == 1;
    return selectedLevel <= activeLevel;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: LoadingAnimationWidget.fallingDot(
        size: 70,
        color: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);
    final authAsync = ref.watch(authProvider);
    final coursesAsync = ref.watch(coursesWithDetailsProvider);
    final activeCourseAsync = ref.watch(activeCourseWithDetailsProvider);
    final hasAttemptedAnyCourseAsync = ref.watch(hasAttemptedAnyCourseProvider);

    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.whenData((user) {
        if (user == null && previous?.value != null) {
          context.go('/welcome');
        }
      });
    });

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.message != null && next.message != previous?.message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: const Color(0xFF856404),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(authStateProvider.notifier).clearMessage();
              },
            ),
          ),
        );
      }
    });

    if (authAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: _buildLoadingIndicator(),
      );
    }

    if (authAsync.value == null &&
        !authAsync.isLoading &&
        !authState.isGuestUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: _buildLoadingIndicator(),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(
              userName: authState.isGuestUser
                  ? "Guest"
                  : profileAsync.when(
                      data: (profile) => profile?.firstName ?? "",
                      loading: () => "",
                      error: (_, __) => "",
                    ),
              isGuestUser: authState.isGuestUser,
              profileImageUrl: authState.isGuestUser
                  ? null
                  : profileAsync.when(
                      data: (profile) => profile?.avatarUrl,
                      loading: () => null,
                      error: (_, __) => null,
                    ),
            ),
            Expanded(
              child: coursesAsync.when(
                loading: _buildLoadingIndicator,
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Failed to load courses.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textColor),
                    ),
                  ),
                ),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No courses available right now.',
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    );
                  }

                  final sortedCourses = List<CourseWithDetails>.from(courses)
                    ..sort((a, b) => a.course.level.compareTo(b.course.level));

                  final allProgressLoaded = sortedCourses.every((c) {
                    final completedMap =
                        ref.watch(completedModulesProvider(c.course.id));
                    final completion =
                        ref.watch(courseCompletionProvider(c.course.id));
                    return !completedMap.isLoading && !completion.isLoading;
                  });

                  if (!allProgressLoaded) return _buildLoadingIndicator();

                  final activeCourseId =
                      activeCourseAsync.valueOrNull?.course.id;
                  final activeIndex = activeCourseId != null
                      ? sortedCourses
                          .indexWhere((c) => c.course.id == activeCourseId)
                      : -1;
                  final targetIndex = (activeIndex >= 0 ? activeIndex : 0)
                      .clamp(0, sortedCourses.length - 1);

                  if (!_hasScrolledToActive) {
                    _hasScrolledToActive = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_pageController.hasClients && targetIndex != 0) {
                        _pageController.jumpToPage(targetIndex);
                      }
                    });
                  }

                  final selectedIndex =
                      (_hasScrolledToActive ? _selectedIndex : targetIndex)
                          .clamp(0, sortedCourses.length - 1);
                  final selectedCourse = sortedCourses[selectedIndex];
                  final activeLevel = activeCourseAsync.maybeWhen(
                    data: (active) => active?.course.level,
                    orElse: () => null,
                  );
                  final isEligible = _isEligibleCourse(
                    selectedLevel: selectedCourse.course.level,
                    activeLevel: activeLevel,
                  );

                  final isCourseCompleted = ref
                          .watch(
                            courseCompletionProvider(selectedCourse.course.id),
                          )
                          .valueOrNull ??
                      false;
                  final hasAttemptedAnyCourse =
                      hasAttemptedAnyCourseAsync.valueOrNull ?? false;
                  final courseButtonText = !isEligible
                      ? 'Locked'
                      : (hasAttemptedAnyCourse
                          ? 'Continue course'
                          : 'Start Course');

                  return Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final pageViewHeight =
                                (constraints.maxHeight * 0.85)
                                    .clamp(420.0, 560.0);

                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(
                                        //     horizontal: 20,
                                        //   ),
                                        //   child: Divider(
                                        //     color: AppColors.borderColor
                                        //         .withValues(alpha: 0.9),
                                        //     height: 20,
                                        //   ),
                                        // ),
                                        SizedBox(
                                          height: pageViewHeight,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            itemCount: sortedCourses.length,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _selectedIndex = index;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              final courseWithDetails =
                                                  sortedCourses[index];
                                              final course =
                                                  courseWithDetails.course;

                                              final completeCourse = ref
                                                  .watch(completeCourseProvider(
                                                    course.id,
                                                  ))
                                                  .valueOrNull;
                                              final completedMap = ref
                                                  .watch(
                                                      completedModulesProvider(
                                                    course.id,
                                                  ))
                                                  .valueOrNull;

                                              bool allLessonsComplete = false;
                                              bool allAssessmentsComplete =
                                                  false;
                                              if (completeCourse != null &&
                                                  completedMap != null) {
                                                final lessonModules =
                                                    completeCourse
                                                        .modules
                                                        .where((m) => !(m.module
                                                                .isAssessment ||
                                                            (m.module
                                                                    .assessmentId
                                                                    ?.trim()
                                                                    .isNotEmpty ??
                                                                false)))
                                                        .toList();
                                                allLessonsComplete =
                                                    lessonModules.isNotEmpty &&
                                                        lessonModules.every(
                                                          (m) =>
                                                              completedMap[m
                                                                  .module.id] ==
                                                              true,
                                                        );

                                                final assessmentModules =
                                                    completeCourse.modules
                                                        .where((m) =>
                                                            m.module
                                                                .isAssessment ||
                                                            (m.module
                                                                    .assessmentId
                                                                    ?.trim()
                                                                    .isNotEmpty ??
                                                                false))
                                                        .toList();
                                                allAssessmentsComplete =
                                                    assessmentModules
                                                            .isNotEmpty &&
                                                        assessmentModules.every(
                                                          (m) =>
                                                              completedMap[m
                                                                  .module.id] ==
                                                              true,
                                                        );
                                              }

                                              return HomeCourseTile(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 10,
                                                ),
                                                title: course.title,
                                                courseLabel:
                                                    'Course ${index + 1}',
                                                levelLabel:
                                                    _levelLabel(course.level),
                                                allLessonsComplete:
                                                    allLessonsComplete,
                                                allAssessmentsComplete:
                                                    allAssessmentsComplete,
                                                onTap: () =>
                                                    _openCourse(course.id),
                                                previewUrl:
                                                    course.soundUrlPreview ??
                                                        '',
                                                previewSourceId:
                                                    'course-preview-${course.id}',
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: _CoursePageIndicator(
                                        count: sortedCourses.length,
                                        currentIndex: selectedIndex,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 8),
                        child: HomeSubCourseTile(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          modulesCount: selectedCourse.totalModules,
                          lessonsCount: selectedCourse.totalLessons,
                          isCompleted: isCourseCompleted,
                          isEligible: isEligible,
                          eligibilityText: isEligible
                              ? 'You are eligible to start this level'
                              : 'Complete previous levels to unlock this level',
                          buttonText: courseButtonText,
                          onStartCourse: isEligible
                              ? () => _openCourse(selectedCourse.course.id)
                              : null,
                          onReviewCourse: () => context.push(
                            '/course/${selectedCourse.course.id}',
                            extra: {'isCompletedCourse': true},
                          ),
                          onRestartCourse: () =>
                              _openCourse(selectedCourse.course.id),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _CoursePageIndicator({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 42 : 14,
          height: 14,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor : const Color(0xFFC9C9C9),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
