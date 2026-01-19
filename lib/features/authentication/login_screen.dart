import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/home/home_screen.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'forgot_password_screen.dart';
import '../../utils/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/loading_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:milpress/features/on_boarding/providers/recommended_course_provider.dart';
import 'providers/login_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate fields when user types
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onEmailChanged() {
    ref.read(loginScreenProvider.notifier).validateEmail(_emailController.text);
    // Clear error when user starts typing
    ref.read(loginScreenProvider.notifier).clearError();
  }

  void _onPasswordChanged() {
    ref.read(loginScreenProvider.notifier).validatePassword(_passwordController.text);
    // Clear error when user starts typing
    ref.read(loginScreenProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    final authState = ref.read(authStateProvider);
    
    // If user is in guest mode, navigate back to home
    if (authState.isGuestUser) {
      context.go('/');
    } else {
      // If not in guest mode, try to pop or go to welcome
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _handleBackButton,
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your personal detail',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter email address',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: !ref.watch(loginScreenProvider).isEmailValid ? Colors.red : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: !ref.watch(loginScreenProvider).isEmailValid ? Colors.red : AppColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        errorText: !ref.watch(loginScreenProvider).isEmailValid && _emailController.text.isNotEmpty 
                          ? 'Please enter a valid email address' 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    if (ref.watch(loginScreenProvider).error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ref.watch(loginScreenProvider).error!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Expanded(child: SizedBox()),
                    CustomButton(
                      text: ref.watch(loginScreenProvider).isLoading ? 'Signing in...' : 'Continue',
                      onPressed: ref.read(loginScreenProvider.notifier).canContinue ? _onContinue : null,
                      isFilled: true,
                      fillColor: ref.read(loginScreenProvider.notifier).canContinue ? AppColors.primaryColor : AppColors.textColor,
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Or', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: ref.watch(loginScreenProvider).isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : SvgPicture.asset('assets/google.svg', height: 24),
                        label: Text(
                          ref.watch(loginScreenProvider).isLoading ? 'Signing in...' : 'Sign in with Google', 
                          style: TextStyle(
                            fontSize: 16, 
                            color: ref.watch(loginScreenProvider).isLoading ? Colors.grey : Colors.black
                          )
                        ),
                        onPressed: ref.watch(loginScreenProvider).isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: ref.watch(loginScreenProvider).isLoading ? Colors.grey.shade300 : const Color(0xFFE0E0E0)
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'By clicking continue, you agree with our ',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            children: const [
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePostAuthenticationNavigation() {
    // Check if there's a recommended course to navigate to
    final recommendedCourse = ref.read(recommendedCourseProvider);
    
    if (recommendedCourse != null) {
      // Navigate to the recommended course and clear the context
      ref.read(recommendedCourseProvider.notifier).clearRecommendedCourse();
      context.go('/course/${recommendedCourse.id}');
    } else {
      // No recommended course, go to home screen
      context.go('/');
    }
  }

  Future<void> _onContinue() async {
    final response = await ref.read(loginScreenProvider.notifier).signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
      ref,
    );

    if (response?.user != null && mounted) {

      final isNewlyVerified = response!.user!.emailConfirmedAt != null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isNewlyVerified
                  ? 'Welcome back! Your email is verified and you\'re all set.'
                  : 'Successfully signed in!'
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Handle post-authentication navigation
      _handlePostAuthenticationNavigation();
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(loginScreenProvider.notifier).signInWithGoogle(ref);

    if (success && mounted) {
      // DON'T invalidate profile here - let auth listener handle it

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed in with Google!'),
          backgroundColor: Colors.green,
        ),
      );
      // Handle post-authentication navigation
      _handlePostAuthenticationNavigation();
    }
  }
} 
