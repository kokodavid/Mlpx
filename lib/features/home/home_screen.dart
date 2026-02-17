import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/home/course_card.dart';
import 'package:milpress/features/home/courses_section.dart';
import 'package:milpress/features/home/ongoing_lesson_card.dart';
import 'package:milpress/features/home/progress_goal_section.dart'
    show ProgressGoalSection, WeeklyGoalProgressCard;
import 'package:milpress/features/weekly_goal/providers/user_goal_providers.dart';
import 'package:milpress/features/weekly_goal/providers/weekly_goal_progress_providers.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../profile/providers/profile_provider.dart';
import '../widgets/email_verification_banner.dart';
import 'home_header.dart';
import 'promotion_card.dart';
import 'jump_in_lesson_section.dart';
import 'providers/ongoing_lesson_provider.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);
    final ongoingLessonAsync = ref.watch(ongoingLessonProvider);
    final authAsync = ref.watch(authProvider);
    final weeklyGoalAsync = ref.watch(activeWeeklyGoalProvider);
    final weeklyProgressAsync = ref.watch(weeklyGoalProgressProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = connectivityAsync.maybeWhen(
      data: isOfflineResult,
      orElse: () => false,
    );

    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.whenData((user) {
        if (user == null && previous?.value != null) {
          context.go('/welcome');
        }
      });
    });

    // Listen for auth messages
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

    // Show loading while auth state is being determined
    if (authAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If auth state is explicitly null (not loading) AND not a guest user, redirect to welcome
    if (authAsync.value == null && !authAsync.isLoading && !authState.isGuestUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return const Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    userName: authState.isGuestUser
                        ? "Guest"
                        : profileAsync.when(
                      data: (profile) => profile?.firstName ?? "",
                      loading: () => "User",
                      error: (_, __) => "User",
                    ),
                    profileImageUrl: authState.isGuestUser
                        ? null
                        : profileAsync.when(
                      data: (profile) => profile?.avatarUrl,
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                  ),
                  const EmailVerificationBanner(),
                  ProgressGoalSection(
                    onTap: () => context.push('/weekly-goal'),
                    goalChild: weeklyGoalAsync.when(
                      data: (goal) {
                        if (goal == null) return null;
                        return weeklyProgressAsync.when(
                          data: (progress) => WeeklyGoalProgressCard(
                            completed: progress.completedLessons,
                            target: goal.goalValue,
                            onTap: () => context.push('/weekly-goal'),
                          ),
                          loading: () => WeeklyGoalProgressCard(
                            completed: 0,
                            target: goal.goalValue,
                            onTap: () => context.push('/weekly-goal'),
                          ),
                          error: (_, __) => WeeklyGoalProgressCard(
                            completed: 0,
                            target: goal.goalValue,
                            onTap: () => context.push('/weekly-goal'),
                          ),
                        );
                      },
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ongoingLessonAsync.when(
                    data: (ongoingLesson) {
                      if (ongoingLesson == null) {
                        return const SizedBox
                            .shrink();
                      }
                      return OngoingLessonCard(
                        title: ongoingLesson.title,
                        progressPercentage: ongoingLesson.progressPercentage,
                        studyTime: ongoingLesson.studyTime,
                        timeLeft: ongoingLesson.timeLeft,
                        onTap: () async {
                          if (ongoingLesson.lessonId != null &&
                              ongoingLesson.courseId != null) {
                            String courseProgressId = '';
                            try {
                              courseProgressId = await ref.read(
                                getOrCreateCourseProgressProvider(
                                  ongoingLesson.courseId!,
                                ).future,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating course progress: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            context.push('/lesson/${ongoingLesson.lessonId}',
                                extra: {
                                  'courseContext': {
                                    'courseId': ongoingLesson.courseId,
                                    'moduleId': ongoingLesson.moduleId,
                                    'courseProgressId': courseProgressId,
                                  },
                                });
                          }
                        },
                      );
                    },
                    loading: () => OngoingLessonCard(
                      title: "Loading...",
                      progressPercentage: 0,
                      studyTime: "Loading...",
                      timeLeft: "Loading...",
                      onTap: () {},
                    ),
                    error: (_, __) =>
                    const SizedBox.shrink(), // Hide card on error
                  ),
                  const SizedBox(height: 16),
                  const PromotionCard(),
                  const SizedBox(height: 10),
                  Text(
                    isOffline ? 'Downloaded lessons' : 'Jump-in lesson',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF232B3A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const JumpInLessonSection(),
                  const SizedBox(height: 24),
                  // const CoursesSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}