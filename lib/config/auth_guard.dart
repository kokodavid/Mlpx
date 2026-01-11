import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/widgets/email_verification_banner.dart';
import '../features/authentication/email_verification_screen.dart';

class AuthGuard {
  static Widget Function(BuildContext, GoRouterState) requireAuth({
    required Widget Function(BuildContext, GoRouterState) builder,
    bool requireEmailVerification = true,
  }) {
    return (context, state) {
      return Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(authProvider);

          return user.when(
            data: (user) {
              if (user == null) {
                // User not authenticated, redirect to login
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
                });
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (requireEmailVerification) {
                final authState = ref.watch(authStateProvider);

                if (!authState.isEmailVerified) {
                  // User authenticated but email not verified
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const Icon(
                              Icons.email_outlined,
                              size: 64,
                              color: Color(0xFF856404),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Email Verification Required',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF856404),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Please verify your email address to access this feature. We\'ve sent a verification link to your inbox.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF856404),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            EmailVerificationBanner(
                              showCloseButton: false,
                              onResendEmail: () {
                                // Additional callback if needed
                              },
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                context.go('/');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF856404),
                                side: const BorderSide(color: Color(0xFF856404)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: const Text('Go to Home'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }

              // User is authenticated and email is verified (if required)
              return builder(context, state);
            },
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) {
              // On error, redirect to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/login');
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        },
      );
    };
  }

  static Widget Function(BuildContext, GoRouterState) requireEmailVerification({
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return requireAuth(
      builder: builder,
      requireEmailVerification: true,
    );
  }

  static Widget Function(BuildContext, GoRouterState) requireAuthOnly({
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return requireAuth(
      builder: builder,
      requireEmailVerification: false,
    );
  }

  static Widget Function(BuildContext, GoRouterState) allowGuest({
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return (context, state) {
      return Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateProvider);
          final isHandlingEmailVerification = ref.watch(isHandlingEmailVerificationProvider);

          // If user is verified, clear the flag immediately
          if (authState.user != null && authState.isEmailVerified && isHandlingEmailVerification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(isHandlingEmailVerificationProvider.notifier).state = false;
            });
          }

          // If handling email verification and user not yet verified, show loading
          if (isHandlingEmailVerification && (!authState.isEmailVerified || authState.user == null)) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE85D04)),
                ),
              ),
            );
          }

          // Allow access if authenticated OR guest user
          if (authState.user != null || authState.isGuestUser) {
            return builder(context, state);
          }

          // Redirect to login if neither authenticated nor guest
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    };
  }

  static Widget Function(BuildContext, GoRouterState) requireAuthenticatedUser({
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return (context, state) {
      return Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateProvider);

          // Only allow access if user is authenticated (not guest)
          if (authState.user != null) {
            return builder(context, state);
          }

          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    };
  }
}