import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import 'dart:async';
import 'package:milpress/services/biometric_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:milpress/features/on_boarding/providers/recommended_course_provider.dart';

class AccountCreatedScreen extends ConsumerStatefulWidget {
  const AccountCreatedScreen({super.key});

  @override
  _AccountCreatedScreenState createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends ConsumerState<AccountCreatedScreen> {
  bool _showSuccess = false;
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSuccess = true;
        });
      }
    });
  }

  Future<void> _checkBiometrics() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  Future<void> _setupBiometrics() async {
    try {
      final authenticated = await _biometricService.authenticate();

      if (authenticated) {
        await _biometricService.enableBiometrics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometric login enabled successfully!')),
          );
          _handlePostAuthenticationNavigation();
        }
      }
    } catch (e) {
      log("Failed to setup biometrics: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to setup biometrics: $e')),
        );
      }
    }
  }

  void _handlePostAuthenticationNavigation() {
    final recommendedCourse = ref.read(recommendedCourseProvider);

    if (recommendedCourse != null) {
      ref.read(recommendedCourseProvider.notifier).clearRecommendedCourse();
      context.go('/course/${recommendedCourse.id}');
    } else {
      context.go('/');
    }
  }

  void _skipBiometrics() {
    _handlePostAuthenticationNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_showSuccess)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipBiometrics,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: _showSuccess
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/loading.gif', height: 100),
                          const SizedBox(height: 32),
                          const Text(
                            'Your account has been created\nsuccessfully',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Now you can start with any course.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 24),
                          // Email verification banner for unverified users
                          if (user.value != null && !authState.isEmailVerified)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFFEAA7), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF856404),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Verify Your Email',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF856404),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'We\'ve sent a verification email to your inbox. Please verify your email to complete your account setup.',
                                    style: TextStyle(
                                      color: Color(0xFF856404),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            ref
                                                .read(authProvider.notifier)
                                                .resendVerificationEmail();

                                            // Show success message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Verification email sent! Please check your inbox.'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF856404),
                                            side: const BorderSide(
                                                color: Color(0xFF856404)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Resend Email',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Show success message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Email verified! Please log in to continue.'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );

                                            // Navigate to login screen after a short delay
                                            await Future.delayed(
                                                const Duration(seconds: 1));
                                            if (context.mounted) {
                                              context.go('/login');
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'I\'ve Verified',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (_isBiometricAvailable) ...[
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _setupBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Enable Biometric Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Center(
                        child: Image.asset('assets/loading.gif', height: 100),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
