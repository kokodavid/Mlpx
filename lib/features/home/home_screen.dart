import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../providers/auth_provider.dart';
import '../../providers/audio_service_provider.dart';
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

  Future<void> _playPreview(String? previewUrl) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview audio available yet.')),
      );
      return;
    }

    await ref.read(audioServiceProvider.notifier).playAudio(previewUrl);
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);
    final authAsync = ref.watch(authProvider);
    final coursesAsync = ref.watch(coursesWithDetailsProvider);
    final activeCourseAsync = ref.watch(activeCourseWithDetailsProvider);

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
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authAsync.value == null &&
        !authAsync.isLoading &&
        !authState.isGuestUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return const Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator()),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
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

                  final selectedIndex = _selectedIndex >= sortedCourses.length
                      ? sortedCourses.length - 1
                      : _selectedIndex;
                  final selectedCourse = sortedCourses[selectedIndex];
                  final activeLevel = activeCourseAsync.maybeWhen(
                    data: (active) => active?.course.level,
                    orElse: () => null,
                  );
                  final isEligible = _isEligibleCourse(
                    selectedLevel: selectedCourse.course.level,
                    activeLevel: activeLevel,
                  );

                  return Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final pageViewHeight =
                                (constraints.maxHeight * 0.74)
                                    .clamp(320.0, 520.0);

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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Divider(
                                            color: AppColors.borderColor
                                                .withValues(alpha: 0.9),
                                            height: 20,
                                          ),
                                        ),
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
                                                onTap: () =>
                                                    _openCourse(course.id),
                                                onPreviewTap: () =>
                                                    _playPreview(
                                                  course.soundUrlPreview,
                                                ),
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
                          isEligible: isEligible,
                          eligibilityText: isEligible
                              ? 'You are eligible to start this level'
                              : 'Complete previous levels to unlock this level',
                          buttonText: isEligible ? 'Start Course' : 'Locked',
                          onStartCourse: isEligible
                              ? () => _openCourse(selectedCourse.course.id)
                              : null,
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
