import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';
import '../authentication/signup_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/providers/auth_provider.dart';

class ProfileCheckerScreen extends ConsumerWidget {
  final VoidCallback? onCreateProfile;
  final VoidCallback? onLater;

  const ProfileCheckerScreen({Key? key, this.onCreateProfile, this.onLater})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  child: Image.asset('assets/orange_logo.png'),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Milpress is your private path to\nstronger reading, writing, and everyday\nconfidence at your own pace',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textColor),
              ),
              const SizedBox(height: 24),
              const Spacer(flex: 3),
              CustomButton(
                text: 'Create Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                isFilled: true,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Later',
                onPressed: onLater ??
                    () async {
                      try {
                        await ref
                            .read(authStateProvider.notifier)
                            .setGuestMode();

                        await Future.delayed(const Duration(milliseconds: 100));

                        if (context.mounted) {
                          context.go('/');
                        }
                      } catch (e) {
                        debugPrint('Error setting guest mode: $e');
                      }
                    },
                isFilled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
