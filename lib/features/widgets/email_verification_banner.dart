import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class EmailVerificationBanner extends ConsumerWidget {
  final VoidCallback? onResendEmail;
  final bool showCloseButton;

  const EmailVerificationBanner({
    super.key,
    this.onResendEmail,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(authProvider);

    // Only show banner if user is logged in but email is not verified
    if (user.value == null || authState.isEmailVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEAA7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF856404),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Email Verification Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF856404),
                    fontSize: 14,
                  ),
                ),
              ),
              if (showCloseButton)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF856404),
                    size: 18,
                  ),
                  onPressed: () {
                    // Hide the banner temporarily
                    ref.read(authStateProvider.notifier).clearMessage();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your email and click the verification link to complete your account setup.',
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
                  onPressed: () {
                    ref.read(authProvider.notifier).resendVerificationEmail();
                    onResendEmail?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF856404),
                    side: const BorderSide(color: Color(0xFF856404)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verified! Please log in to continue.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    // Navigate to login screen after a short delay
                    await Future.delayed(const Duration(seconds: 1));
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
    );
  }
} 