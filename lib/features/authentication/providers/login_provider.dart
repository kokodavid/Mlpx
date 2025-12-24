import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/supabase_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/auth_error_helper.dart';

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
    bool clearError = false,
    bool? isEmailValid,
    bool? isPasswordValid,
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
    state = state.copyWith(
      error: error,
      clearError: error == null,
    );
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
    return !state.isLoading &&
        state.isEmailValid &&
        state.isPasswordValid &&
        state.error == null;
  }

  // Email/Password authentication
  Future<AuthResponse?> signInWithEmailAndPassword(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        return response;
      } else {
        setError('Authentication failed. Please check your credentials.');
        return null;
      }
    } on AuthException catch (e) {
      setError(AuthErrorHelper.message(e));
      return null;
    } catch (e) {
      setError(AuthErrorHelper.message(e));
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
      setError(AuthErrorHelper.message(e));
      return false;
    } catch (e) {
      final presentation = AuthErrorHelper.present(e);
      if (presentation.showToUser) {
        setError(presentation.message);
      } else {
        setError(null);
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
