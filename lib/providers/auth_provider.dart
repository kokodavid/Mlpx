import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_error_helper.dart';

class AuthState {
  final User? user;
  final String? message;
  final bool isLoading;
  final bool isEmailVerified;
  final bool isGuestUser;

  AuthState({
    this.user,
    this.message,
    this.isLoading = false,
    this.isEmailVerified = false,
    this.isGuestUser = false,
  });

  AuthState copyWith({
    User? user,
    String? message,
    bool? isLoading,
    bool? isEmailVerified,
    bool? isGuestUser,
  }) {
    return AuthState(
      user: user ?? this.user,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isGuestUser: isGuestUser ?? this.isGuestUser,
    );
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState()) {
    _initializeGuestMode();
    _listenToAuthChanges();
  }

  Future<void> _initializeGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('is_guest_user') ?? false;

    if (isGuest) {
      state = state.copyWith(isGuestUser: true);
    }
  }

  void _listenToAuthChanges() {
    // Listen to auth state changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      final isEmailVerified = user?.emailConfirmedAt != null;

      // If user is authenticated, clear guest mode
      if (user != null) {
        _clearGuestMode();
      }

      state = state.copyWith(
        user: user,
        isEmailVerified: isEmailVerified,
        isGuestUser: user == null ? state.isGuestUser : false,
      );
    });
  }

  Future<void> _clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest_user');
    state = state.copyWith(isGuestUser: false);
  }

  void showMessage(String message) {
    state = state.copyWith(message: message);
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_user', true);
    state = state.copyWith(isGuestUser: true);
  }

  Future<void> clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest_user');
    state = state.copyWith(isGuestUser: false);
  }

  Future<void> migrateGuestDataToUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all guest data keys
      final keys = prefs.getKeys();
      final guestKeys = keys.where((key) => key.startsWith('guest_')).toList();

      // Migrate each guest data to user data
      for (final guestKey in guestKeys) {
        final guestData = prefs.getString(guestKey);
        if (guestData != null) {
          // Create user-specific key
          final userKey = guestKey.replaceFirst('guest_', 'user_${userId}_');
          await prefs.setString(userKey, guestData);

          // Remove guest data
          await prefs.remove(guestKey);
        }
      }

      // Clear guest mode
      await clearGuestMode();

      log('Guest data migrated successfully for user: $userId');
    } catch (e) {
      log('Error migrating guest data: $e');
      rethrow;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initializeAuthState();

    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = AsyncValue.data(user);

      if (user != null && user.emailConfirmedAt == null) {
        _showEmailVerificationMessage();
      }
    });
  }

  Future<void> _initializeAuthState() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      final user = session?.user;

      state = AsyncValue.data(user);

      if (user != null && user.emailConfirmedAt == null) {
        _showEmailVerificationMessage();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _showEmailVerificationMessage() {
    final authState = ref.read(authStateProvider.notifier);
    authState
        .showMessage('Please verify your email to complete authentication');
  }

  void _showTransientMessage(String message) {
    final authState = ref.read(authStateProvider.notifier);
    authState.showMessage(message);
    Future.delayed(const Duration(seconds: 4), authState.clearMessage);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      state = const AsyncValue.loading();

      final wasGuest = ref.read(authStateProvider).isGuestUser;

      log('Attempting sign up for email: $email');
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      log('Sign up response: user=${response.user}');

      if (response.user != null) {
        if (wasGuest) {
          final authState = ref.read(authStateProvider.notifier);
          await authState.migrateGuestDataToUser(response.user!.id);
        }

        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'first_name': firstName,
          'last_name': lastName,
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          final upsertResult = await SupabaseConfig.client
              .from('profiles')
              .upsert(userData)
              .select();
          if (upsertResult.isEmpty) {
            throw Exception('Profile creation failed.');
          }
        } catch (upsertError) {
          log('Profile upsert failed: $upsertError');
          rethrow;
        }

        state = AsyncValue.data(response.user);

        if (response.user!.emailConfirmedAt == null) {
          _showEmailVerificationMessage();
        }
      }
    } catch (e, st) {
      log('Sign up failed: $e');
      _showTransientMessage(AuthErrorHelper.message(e));
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> isEmailVerified() async {
    final user = state.value;
    return user?.emailConfirmedAt != null;
  }

  Future<void> checkEmailVerificationStatus() async {
    try {
      // Get the current session from Supabase to check if email was verified
      final session = SupabaseConfig.client.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        // Update the state with the current user (which may have updated email verification status)
        state = AsyncValue.data(user);

        // Check if email is now verified
        if (user.emailConfirmedAt != null) {
          // Email is verified, clear any verification messages
          final authState = ref.read(authStateProvider.notifier);
          authState.clearMessage();
        } else {
          // Email is still not verified
          _showEmailVerificationMessage();
        }
      }
    } catch (e) {
      // If there's an error, don't change the current state
      log('Error checking email verification status: $e');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = state.value;
      if (user != null && user.email != null) {
        await SupabaseConfig.client.auth.resend(
          type: OtpType.signup,
          email: user.email!,
        );

        final authState = ref.read(authStateProvider.notifier);
        authState
            .showMessage('Verification email sent! Please check your inbox.');
      }
    } catch (e) {
      final authState = ref.read(authStateProvider.notifier);
      authState
          .showMessage('Failed to send verification email. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '980044039959-gf7e5l4u9kts65970co8vaqkb7gjt1o6.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google ID token is null');
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null && response.session != null) {
        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'first_name': googleUser.displayName?.split(' ').first ?? '',
          'last_name': googleUser.displayName?.split(' ').last ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        };

        log('User data: $userData');

        await SupabaseConfig.client.from('profiles').upsert(userData).select();

        state = AsyncValue.data(response.user);

        final authState = ref.read(authStateProvider.notifier);
        authState.showMessage('Successfully signed in with Google!');

        await Future.delayed(const Duration(seconds: 2));

        authState.clearMessage();
      } else {
        throw Exception('Google Sign-In failed: No user or session returned');
      }
    } catch (e, st) {
      log('Google sign-in failed: $e');
      final presentation = AuthErrorHelper.present(e);
      if (presentation.showToUser) {
        _showTransientMessage(presentation.message);
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = const AsyncValue.loading();
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.milpress://login-callback/',
      );
    } catch (e, st) {
      final presentation = AuthErrorHelper.present(e);
      if (presentation.showToUser) {
        _showTransientMessage(presentation.message);
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();

      // Clear all data from Supabase
      await SupabaseConfig.client.auth.signOut();

      // Reset the state
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Helper providers for guest mode
final isGuestUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isGuestUser;
});

final isAuthenticatedOrGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user != null || authState.isGuestUser;
});
