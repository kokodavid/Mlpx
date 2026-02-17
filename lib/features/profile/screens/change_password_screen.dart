import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../../utils/app_colors.dart';
import '../providers/change_password_provider.dart';
import '../providers/profile_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late TextEditingController _emailController;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();

    // Pre-fill email from the currently loaded profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email =
          ref.read(profileProvider).value?.email ?? '';
      if (email.isNotEmpty) {
        ref.read(changePasswordProvider.notifier).prefillEmail(email);
        _emailController.text = email;
        _checkEmailValid();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _checkEmailValid() {
    setState(() {
      _isEmailValid = _emailController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pwState = ref.watch(changePasswordProvider);

    // Listen for success to show the bottom sheet
    ref.listen(changePasswordProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        _showCheckEmailSheet(context, next.email);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.copBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text(
              'Change password?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.copBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) {
                ref.read(changePasswordProvider.notifier).setEmail(v);
                _checkEmailValid();
              },
              decoration: InputDecoration(
                hintText: 'abc@example.xyz',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Enter you email address to receive a link to \nreset your password',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textColor,
              ),
            ),

            // Error message
            if (pwState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  pwState.errorMessage!,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Continue button
            CustomButton(
              text: 'Continue',
              onPressed: (!pwState.isLoading && _isEmailValid)
                  ? () => ref
                  .read(changePasswordProvider.notifier)
                  .sendResetEmail()
                  : null,
              isFilled: true,
              fillColor: !_isEmailValid ? AppColors.textColor : AppColors.primaryColor,
              isLoading: pwState.isLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCheckEmailSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Check your email!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.copBlue,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We have sent an email to \n$email. '
                    "Didn't receive it? \nCheck your spam folder or try again.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Got it',
                onPressed: () {
                  Navigator.of(context).pop(); // close sheet
                  context.pop(); // go back to edit profile
                },
                isFilled: true,
                fillColor: AppColors.primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }
}