import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/supabase_config.dart';
import '../../../providers/auth_provider.dart';
import '../../course/providers/course_provider.dart';
import '../../user_progress/providers/user_progress_providers.dart';

// State class for login screen
class LoginScreenState {
  final bool isLoading;
  final String? error;
  final bool isEmailValid;
  final bool isPasswordValid;

  LoginScreenState({
    this.isLoading = false,
    this.error,
    this.isEmailValid = true,
    this.isPasswordValid = true,
  });

  LoginScreenState copyWith({
    bool? isLoading,
    String? error,
    bool? isEmailValid,
    bool? isPasswordValid,
    bool clearError = false,
  }) {
    return LoginScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
    );
  }
}

// Notifier class for login screen business logic
class LoginScreenNotifier extends StateNotifier<LoginScreenState> {
  LoginScreenNotifier() : super(LoginScreenState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    if (error == null) {
      state = state.copyWith(clearError: true);
    } else {
      state = state.copyWith(error: error);
    }
  }

  void validateEmail(String email) {
    final isValid = email.isEmpty || _isValidEmail(email.trim());
    state = state.copyWith(isEmailValid: isValid);
  }

  void validatePassword(String password) {
    final isValid = password.isNotEmpty;
    state = state.copyWith(isPasswordValid: isValid);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get canContinue {
    return state.isEmailValid && state.isPasswordValid && state.error == null;
  }

  bool _isNetworkError(String error) {
    return error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('timeout') ||
        error.toLowerCase().contains('unreachable');
  }

  // Email/Password authentication
  Future<AuthResponse?> signInWithEmailAndPassword(
      String email,
      String password,
      WidgetRef ref,
      ) async {
    setLoading(true);
    setError(null);

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // NEW: Fetch user data from Supabase after successful sign-in
        final userId = response.user!.id;

        await ref.read(fetchAndCacheCourseProgressProvider(userId).future);
        await ref.read(fetchAndCacheModuleProgressProvider(userId).future);
        await ref.read(fetchAndCacheLessonProgressProvider(userId).future);

        // Invalidate providers to refresh UI
        ref.invalidate(activeCourseWithDetailsProvider);
        ref.invalidate(upcomingCoursesWithDetailsProvider);
        ref.invalidate(completedCoursesWithDetailsProvider);

        return response;
      } else {
        setError('Authentication failed. Please check your credentials.');
        return null;
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        setError('Authentication failed. Please check your credentials.');
      } else {
        setError('An unexpected error occurred');
      }
      return null;
    } catch (e) {
      setError('An unexpected error occurred');
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Google authentication
  Future<bool> signInWithGoogle(WidgetRef ref) async {
    setLoading(true);
    setError(null);

    try {
      await ref.read(authProvider.notifier).signInWithGoogle();

      // Check if authentication was successful
      final user = ref.read(authProvider).value;

      if (user != null) {
        return true;
      } else {
        setError('Google Sign-In failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      if (e.message.contains('OAuth')) {
        setError('Google Sign-In is not configured properly. Please contact support.');
      } else if (_isNetworkError(e.message)) {
        setError('Network error. Please check your internet connection.');
      } else {
        setError('Google Sign-In failed: ${e.message}');
      }
      return false;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        setError('Network error. Please check your internet connection.');
      } else if (e.toString().contains('cancelled')) {
        setError(null); // User cancelled, don't show error
      } else {
        setError('Google Sign-In failed. Please try again.');
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Clear error when user starts typing
  void clearError() {
    if (state.error != null) {
      setError(null);
    }
  }
}

// Provider for login screen state
final loginScreenProvider = StateNotifierProvider<LoginScreenNotifier, LoginScreenState>((ref) {
  return LoginScreenNotifier();
});