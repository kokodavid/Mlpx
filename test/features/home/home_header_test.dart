import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/home/home_header.dart';

void main() {
  group('HomeHeader layout and text', () {
    testWidgets('renders avatar, flame widget and greeting pill',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: HomeHeader(
            userName: 'Alex',
            isGuestUser: false,
            currentDateTime: DateTime(2026, 2, 16, 9),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(
          find.byKey(const Key('home_header_greeting_pill')), findsOneWidget);
      expect(find.text('FEB 16, 2026'), findsOneWidget);
      expect(find.text('Good Morning'), findsOneWidget);
    });

    testWidgets('shows afternoon greeting', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: HomeHeader(
            userName: 'Alex',
            isGuestUser: false,
            currentDateTime: DateTime(2026, 2, 16, 14),
          ),
        ),
      );

      expect(find.text('Good Afternoon'), findsOneWidget);
    });

    testWidgets('shows evening greeting', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: HomeHeader(
            userName: 'Alex',
            isGuestUser: false,
            currentDateTime: DateTime(2026, 2, 16, 20),
          ),
        ),
      );

      expect(find.text('Good Evening'), findsOneWidget);
    });
  });

  group('HomeHeader interactions', () {
    testWidgets('authenticated user can navigate to profile and weekly goal',
        (tester) async {
      final router = _buildRouter(
        child: HomeHeader(
          userName: 'Alex',
          isGuestUser: false,
          currentDateTime: DateTime(2026, 2, 16, 9),
        ),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_header_streak_button')));
      await tester.pumpAndSettle();
      expect(find.text('Weekly Goal Page'), findsOneWidget);

      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_header_avatar_button')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Page'), findsOneWidget);
    });

    testWidgets('guest taps do not navigate', (tester) async {
      final router = _buildRouter(
        child: HomeHeader(
          userName: 'Guest',
          isGuestUser: true,
          currentDateTime: DateTime(2026, 2, 16, 9),
        ),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_header_streak_button')));
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Weekly Goal Page'), findsNothing);

      await tester.tap(find.byKey(const Key('home_header_avatar_button')));
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Profile Page'), findsNothing);
    });
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

GoRouter _buildRouter({required Widget child}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('Home Page'),
              child,
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(
          body: Text('Profile Page'),
        ),
      ),
      GoRoute(
        path: '/weekly-goal',
        builder: (context, state) => const Scaffold(
          body: Text('Weekly Goal Page'),
        ),
      ),
    ],
  );
}
