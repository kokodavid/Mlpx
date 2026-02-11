import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/course/screens/course_screen.dart';
import 'package:milpress/features/course/screens/course_details_screen.dart';
import 'package:milpress/features/home/home_screen.dart';
import 'package:milpress/features/assessment/assessment_screen.dart';
import 'package:milpress/features/assessment/models/assessment_config.dart';
import 'package:milpress/features/reviews/review_screen.dart';
import 'package:milpress/features/reviews/bookmarks_screen.dart';
import 'package:milpress/features/reviews/lesson_history_screen.dart';
import 'package:milpress/features/reviews/downloaded_lessons_screen.dart';
import 'package:milpress/features/widgets/custom_bottom_nav.dart';
import 'package:milpress/features/lesson/lesson_screen.dart';
import 'package:milpress/features/lessons_v2/screens/lesson_attempt_screen.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/screens/lesson_complete_v2_screen.dart';
import 'package:milpress/splash_screen.dart';
import 'package:milpress/features/authentication/login_screen.dart';
import 'package:milpress/features/authentication/signup_screen.dart';
import 'package:milpress/features/authentication/account_created_screen.dart';
import 'package:milpress/features/on_boarding/welcome_screen.dart';
import 'package:milpress/features/on_boarding/course_prep.dart';
import 'package:milpress/features/on_boarding/result_screen.dart';
import 'package:milpress/features/lesson/complete_lesson_screen.dart';
import 'package:milpress/features/lesson/offline_lesson_screen.dart';
import 'package:milpress/features/on_boarding/profile_checker.dart';
import 'package:milpress/features/profile/profile_page.dart';
import 'package:milpress/features/profile/screens/about_screen.dart';
import 'package:milpress/features/weekly_goal/screens/weekly_goal_screen.dart';
import 'package:milpress/features/course_assessment/screens/assessment_play_screen.dart';
import '../features/authentication/email_verification_screen.dart';
import 'auth_guard.dart';

enum AppRoute {
  splash,
  welcome,
  coursePrep,
  login,
  signup,
  accountCreated,
  main,
  home,
  course,
  courseDetails,
  review,
  lesson,
  lessonAttempt,
  lessonCompleteV2,
  offlineLesson,
  assessment,
  assessmentResult,
  lessonComplete,
  profile,
  about,
  lessonHistory,
  weeklyGoal,
  courseAssessment,
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final uri = state.uri;

      if (uri.scheme == 'milpress') {
        if (uri.host == 'password-reset-success' ||
            uri.path == '/password-reset-success') {
          return '/login';
        }
      }

      if (uri.scheme == 'https' &&
          uri.host == 'reset-password.milpress.org' &&
          uri.path == '/password-reset-success') {
        return '/login';
      }

      return null;
    },
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      // Authentication routes
      GoRoute(
        path: '/welcome',
        name: AppRoute.welcome.name,
        builder: (context, state) => WelcomeScreen(),
      ),
      GoRoute(
        path: '/course-prep',
        name: AppRoute.coursePrep.name,
        builder: (context, state) => const CoursePrepScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/password-reset-success',
        name: 'passwordResetSuccess',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup.name,
        builder: (context, state) => SignupScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'emailVerification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/account-created',
        name: AppRoute.accountCreated.name,
        builder: (context, state) => AccountCreatedScreen(),
      ),
      // Main app shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          final uri = state.uri;
          int selectedIndex = 0;
          
          if (uri.path.startsWith('/course')) {
            selectedIndex = 1;
          } else if (uri.path.startsWith('/review')) {
            selectedIndex = 2;
          }

          return SafeArea(
            child: Scaffold(
              body: child,
              bottomNavigationBar: CustomBottomNav(
                currentIndex: selectedIndex,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go('/');
                      break;
                    case 1:
                      context.go('/course');
                      break;
                    case 2:
                      context.go('/review');
                      break;
                  }
                },
              ),
            ),
          );
        },
        routes: [
          // Home route - allows guest access
          GoRoute(
            path: '/',
            name: AppRoute.home.name,
            builder: AuthGuard.allowGuest(
              builder: (context, state) => const HomeScreen(),
            ),
          ),
          // Course routes - allow guest access
          GoRoute(
            path: '/course',
            name: AppRoute.course.name,
            builder: AuthGuard.allowGuest(
              builder: (context, state) => const CourseScreen(),
            ),
            routes: [
              GoRoute(
                path: ':courseId',
                name: AppRoute.courseDetails.name,
                builder: AuthGuard.allowGuest(
                  builder: (context, state) {
                    final courseId = state.pathParameters['courseId']!;
                    return CourseDetailsScreen(courseId: courseId);
                  },
                ),
              ),
            ],
          ),
          // Review route - allows guest access
          GoRoute(
            path: '/review',
            name: AppRoute.review.name,
            builder: AuthGuard.allowGuest(
              builder: (context, state) => const ReviewScreen(),
            ),
          ),
        ],
      ),
      // Standalone routes (no bottom nav) - require authenticated user (not guest)
      GoRoute(
        path: '/lesson-attempt',
        name: AppRoute.lessonAttempt.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final lessonDefinition =
                extra?['lessonDefinition'] as LessonDefinition?;
            final lessonId = extra?['lessonId'] as String?;
            final initialStepIndex =
                extra?['initialStepIndex'] as int? ?? 0;
            final isReattempt = extra?['isReattempt'] as bool? ?? false;
            return LessonAttemptScreen(
              lessonDefinition: lessonDefinition,
              lessonId: lessonId,
              initialStepIndex: initialStepIndex,
              isReattempt: isReattempt,
            );
          },
        ),
      ),
      GoRoute(
        path: '/lesson-complete-v2',
        name: AppRoute.lessonCompleteV2.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return LessonCompleteV2Screen(
              lessonId: extra['lessonId'] as String? ?? '',
              moduleId: extra['moduleId'] as String? ?? '',
              lessonTitle: extra['lessonTitle'] as String? ?? 'Lesson',
              timeRemainingLabel: extra['timeRemainingLabel'] as String?,
            );
          },
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        name: AppRoute.lesson.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId']!;
            return LessonScreen(lessonId: lessonId);
          },
        ),
      ),
      GoRoute(
        path: '/offline-lesson/:lessonId',
        name: AppRoute.offlineLesson.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId']!;
            return OfflineLessonScreen(lessonId: lessonId);
          },
        ),
      ),
      // Bookmarks route - requires authenticated user (not guest)
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) => const BookmarksScreen(),
        ),
      ),
      // Lesson History route - requires authenticated user (not guest)
      GoRoute(
        path: '/lesson-history',
        name: AppRoute.lessonHistory.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) => const LessonHistoryScreen(),
        ),
      ),
      // Downloaded Lessons route - requires authenticated user (not guest)
      GoRoute(
        path: '/downloaded-lessons',
        name: 'downloadedLessons',
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) => const DownloadedLessonsScreen(),
        ),
      ),
      // Assessment routes - PUBLIC (no auth required for onboarding)
      GoRoute(
        path: '/assessment',
        name: AppRoute.assessment.name,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final questions = extra['questions'] as List<Map<String, dynamic>>? ?? [];
          final config = extra['config'] as AssessmentConfig?;
          final allQuestions = extra['allQuestions'] as List<Map<String, dynamic>>?;
          
          if (config == null) {
            // If no config provided, show error
            return const Scaffold(
              body: Center(
                child: Text('Error: No assessment configuration provided'),
              ),
            );
          }
          
          return AssessmentScreen(questions: questions, config: config, allQuestions: allQuestions);
        },
      ),
      // Assessment result route - PUBLIC (no auth required for onboarding)
      GoRoute(
        path: '/result',
        name: 'onboardingResult',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: ResultScreen(
              isSuccess: extra['isSuccess'] as bool? ?? false,
              score: extra['score'] as int? ?? 0,
              totalQuestions: extra['totalQuestions'] as int? ?? 0,
              stage: extra['stage'] as String? ?? '',
              stageScores: extra['stageScores'] as Map<String, int>?,
              totalQuestionsPerStage: extra['totalQuestionsPerStage'] as Map<String, int>?,
              isFinalResult: extra['isFinalResult'] as bool? ?? false,
              allQuestions: extra['allQuestions'] as List<Map<String, dynamic>>?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),
      GoRoute(
        path: '/lesson-complete/:lessonId',
        name: AppRoute.lessonComplete.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId']!;
            return CompleteLessonScreen(
              lessonId: lessonId,
            );
          },
        ),
      ),
      // Profile route - requires authenticated user (not guest)
      GoRoute(
        path: '/profile',
        name: AppRoute.profile.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) => const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/weekly-goal',
        name: AppRoute.weeklyGoal.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) => const WeeklyGoalScreen(),
        ),
      ),
      // Course assessment route - requires authenticated user
      GoRoute(
        path: '/course-assessment/:assessmentId',
        name: AppRoute.courseAssessment.name,
        builder: AuthGuard.requireAuthenticatedUser(
          builder: (context, state) {
            final assessmentId = state.pathParameters['assessmentId']!;
            return AssessmentPlayScreen(assessmentId: assessmentId);
          },
        ),
      ),
      // Profile checker - PUBLIC (no auth required for onboarding)
      GoRoute(
        path: '/profile_checker',
        builder: (context, state) => ProfileCheckerScreen(),
      ),
      GoRoute(
        path: '/about',
        name: AppRoute.about.name,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    // Optional: Add error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}); 
