import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/edit_profile_service.dart';
import 'edit_profile_provider.dart';

class ChangePasswordState {
  final String email;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ChangePasswordState({
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  bool get isValid => email.trim().isNotEmpty && email.contains('@');

  ChangePasswordState copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return ChangePasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Change password state provider
final changePasswordProvider =
StateNotifierProvider.autoDispose<ChangePasswordNotifier, ChangePasswordState>(
        (ref) {
      final service = ref.watch(editProfileServiceProvider);
      return ChangePasswordNotifier(service);
    });

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final EditProfileService _service;

  ChangePasswordNotifier(this._service) : super(const ChangePasswordState());

  /// Update the email field in state
  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      clearError: true,
      isSuccess: false,
    );
  }

  /// Pre-fill the email field from the currently signed-in user
  void prefillEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  /// Send the password reset email via Supabase Auth
  Future<void> sendResetEmail() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      final success = await _service.sendPasswordResetEmail(state.email);

      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
          'Failed to send reset email. Please check the address and try again.',
        );
        return;
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Clear any error message shown in the UI
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset the entire state (e.g. when the screen is closed)
  void reset() {
    state = const ChangePasswordState();
  }
}