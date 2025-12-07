import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../widgets/loading_screen.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  int _step = 0;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoadingDialogShowing = false;
  String? _emailError;
  String? _passwordError;

  bool get _canContinue {
    if (_step == 0) {
      return _firstNameController.text.trim().isNotEmpty &&
          _secondNameController.text.trim().isNotEmpty;
    } else if (_step == 1) {
      return _emailController.text.trim().isNotEmpty && _emailError == null;
    } else if (_step == 2) {
      return _passwordController.text.trim().isNotEmpty && _passwordError == null;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onChanged);
    _secondNameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_step == 1) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() => _emailError = null);
      } else if (!_isValidEmail(email)) {
        setState(() => _emailError = 'Please enter a valid email address');
      } else {
        setState(() => _emailError = null);
      }
    } else if (_step == 2) {
      final password = _passwordController.text;
      if (password.isEmpty) {
        setState(() => _passwordError = null);
      } else if (password.length < 6) {
        setState(() => _passwordError = 'Password must be at least 6 characters');
      } else {
        setState(() => _passwordError = null);
      }
    } else {
      setState(() {});
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\u0000?');
    return emailRegex.hasMatch(email);
  }

  void _handleBackButton() {
    final authState = ref.read(authStateProvider);
    
    if (_step == 0) {
      if (authState.isGuestUser) {
        context.go('/');
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/welcome');
        }
      }
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _onContinue() async {
    if (_step == 0 && _canContinue) {
      setState(() => _step = 1);
    } else if (_step == 1 && _canContinue) {
      setState(() => _step = 2);
    } else if (_step == 2 && _canContinue) {
      // Show loading screen
      setState(() {
        _isLoadingDialogShowing = true;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingScreen(message: '',),
      );
      try {
        await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _secondNameController.text.trim(),
        );
        if (mounted) {
          if (_isLoadingDialogShowing && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); 
            setState(() {
              _isLoadingDialogShowing = false;
            });
          }
          _handlePostAuthenticationNavigation();
        }
      } catch (e) {
        if (mounted) {
          if (_isLoadingDialogShowing && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); 
            setState(() {
              _isLoadingDialogShowing = false;
            });
          }

          String errorMessage = "There was a problem creating your account. Please try again.";
          if (e is AuthApiException) {
            errorMessage = e.message;
          }

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Account Creation Failed'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _handlePostAuthenticationNavigation() {
    context.go('/account-created');
  }

  Future<void> _signUpWithGoogle() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) {
        _handlePostAuthenticationNavigation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign up with Google')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
                          onPressed: authState.isLoading ? null : _handleBackButton,
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: authState.isLoading ? null : () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (_step == 0) ...[
                            const Text(
                              'What is your name',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _firstNameController,
                              enabled: !authState.isLoading,
                              decoration: InputDecoration(
                                hintText: 'First Name',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _secondNameController,
                              enabled: !authState.isLoading,
                              decoration: InputDecoration(
                                hintText: 'Second Name',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ] else if (_step == 1) ...[
                            const Text(
                              'What is your email address',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _emailController,
                              enabled: !authState.isLoading,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'abc@example.xyz',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                errorText: _emailError,
                              ),
                            ),
                          ] else if (_step == 2) ...[
                            const Text(
                              'Create password',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _passwordController,
                              enabled: !authState.isLoading,
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: authState.isLoading ? null : () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(
                          text: authState.isLoading 
                              ? 'Creating Account...' 
                              : (_step < 2 ? 'Continue' : 'Create Profile'),
                          onPressed: _canContinue && !authState.isLoading ? _onContinue : null,
                          isFilled: true,
                          fillColor: _canContinue && !authState.isLoading ? AppColors.primaryColor : AppColors.textColor,
                        ),
                        const SizedBox(height: 20),
                        if (_step == 0) ...[
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
                              icon: SvgPicture.asset('assets/google.svg', height: 24),
                              label: const Text('Sign up with Google',
                                  style: TextStyle(fontSize: 16, color: Colors.black)),
                              onPressed: authState.isLoading ? null : _signUpWithGoogle,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
