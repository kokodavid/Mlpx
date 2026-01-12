import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import '../../providers/auth_provider.dart' hide AuthState;
import '../../utils/app_strings.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Global flag to prevent router redirects during email verification
final isHandlingEmailVerificationProvider = StateProvider<bool>((ref) => false);

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set flag immediately to prevent redirects while on this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isHandlingEmailVerificationProvider.notifier).state = true;
      }
    });

    _setupAuthListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    // Listen for auth state changes from the deep link
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final event = data.event;
      final session = data.session;

      // Only proceed if user is verified
      if (session != null && session.user.emailConfirmedAt != null && !_hasNavigated) {
        // Deep link has completed verification
        // Clear flag immediately so router can proceed
        ref.read(isHandlingEmailVerificationProvider.notifier).state = false;

        // Then navigate
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;

    // Clear flag before navigation
    ref.read(isHandlingEmailVerificationProvider.notifier).state = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully! Welcome!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    context.go('/');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When user returns from email app, just wait for auth listener to fire
    // No need to manually check - the deep link will trigger auth state change
  }

  Future<void> _openEmailApp(BuildContext context) async {
    try {
      bool launched = false;

      if (Platform.isAndroid) {
        try {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.APP_EMAIL',
            flags: <int>[
              0x40000000, // FLAG_ACTIVITY_NEW_TASK
              0x04000000, // FLAG_ACTIVITY_MULTIPLE_TASK
            ],
          );
          await intent.launch();
          launched = true;
        } catch (e) {
          print('Email chooser intent failed: $e');
        }
      } else if (Platform.isIOS) {
        final mailUri = Uri.parse('message://');
        if (await canLaunchUrl(mailUri)) {
          await launchUrl(mailUri, mode: LaunchMode.externalApplication);
          launched = true;
        }
      }

      if (!launched) {
        final uri = Uri.parse('mailto:');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app. Please check your email manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error opening email app: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please open your email app manually to verify'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            ref.read(isHandlingEmailVerificationProvider.notifier).state = false;
            context.go('/login');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () {
              // Handle help/chat action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Please verify your email',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Before you continue please verify the email we \nsent to you: $email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Image.asset(
                'assets/email_verified.png',
                width: 200,
                height: 150,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              CustomButton(
                text: AppStrings.openEmailToApprove,
                onPressed: () => _openEmailApp(context),
                isFilled: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}