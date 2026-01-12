import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/course/providers/course_provider.dart';
import '../utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/user_progress/providers/course_progress_providers.dart';
import '../features/user_progress/providers/user_progress_providers.dart';

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
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      final isEmailVerified = user?.emailConfirmedAt != null;

      if (user != null) {
        await _clearGuestMode();
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

  Future<void> migrateGuestDataToUser(String userId, Ref ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final guestKeys = keys.where((key) => key.startsWith('guest_')).toList();

      for (final guestKey in guestKeys) {
        final guestData = prefs.getString(guestKey);
        if (guestData != null) {
          final userKey = guestKey.replaceFirst('guest_', 'user_${userId}_');
          await prefs.setString(userKey, guestData);
          await prefs.remove(guestKey);
        }
      }

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
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;

      if (user != null) {
        final wasGuest = ref.read(authStateProvider).isGuestUser;
        if (wasGuest) {
          await ref.read(authStateProvider.notifier)
              .migrateGuestDataToUser(user.id, ref);
        }
      }

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
    authState.showMessage('Please verify your email to complete authentication');
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

      // Sign up with email redirect URL for verification
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
        // CRITICAL: This tells Supabase where to redirect after email verification
        emailRedirectTo: 'io.supabase.milpress://email-callback/',
      );

      log('Sign up response: user=${response.user}');

      if (response.user != null) {
        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'first_name': firstName,
          'last_name': lastName,
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          await SupabaseConfig.client.from('profiles').upsert(userData).select();
        } catch (upsertError) {
          log('Profile upsert failed: $upsertError');
          rethrow;
        }

        if (wasGuest) {
          await ref.read(authStateProvider.notifier)
              .migrateGuestDataToUser(response.user!.id, ref);
        }

        state = AsyncValue.data(response.user);

        // Invalidate all user-dependent providers
        _invalidateUserProviders();
      }
    } catch (e, st) {
      log('Sign up failed: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '1082890638229-cngrhi1tt6na7t5slca3o70mmn0p44gh.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('Google ID token is null');

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

        final wasGuest = ref.read(authStateProvider).isGuestUser;
        if (wasGuest) {
          await ref.read(authStateProvider.notifier)
              .migrateGuestDataToUser(response.user!.id, ref);
        }

        state = AsyncValue.data(response.user);

        // Invalidate all user-dependent providers
        _invalidateUserProviders();

        final authState = ref.read(authStateProvider.notifier);
        authState.showMessage('Successfully signed in with Google!');
        await Future.delayed(const Duration(seconds: 2));
        authState.clearMessage();
      } else {
        throw Exception('Google Sign-In failed: No user or session returned');
      }
    } catch (e, st) {
      log('Google sign-in failed: $e');
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
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await SupabaseConfig.client.auth.signOut();

      // Invalidate all user-dependent providers
      _invalidateUserProviders();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> isEmailVerified() async {
    final user = state.value;
    return user?.emailConfirmedAt != null;
  }

  Future<void> checkEmailVerificationStatus() async {
    try {
      log('Refreshing session from Supabase server...');

      // CRITICAL FIX: Refresh session from server to get latest user data
      final response = await SupabaseConfig.client.auth.refreshSession();
      final user = response.session?.user;

      log('Refreshed user data: emailConfirmedAt=${user?.emailConfirmedAt}');

      if (user != null) {
        state = AsyncValue.data(user);
        if (user.emailConfirmedAt != null) {
          log('Email is verified!');
          final authState = ref.read(authStateProvider.notifier);
          authState.clearMessage();
        } else {
          log('Email still not verified');
          _showEmailVerificationMessage();
        }
      }
    } catch (e, st) {
      log('Error checking email verification status: $e');
      // Don't rethrow - just log the error and keep current state
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
        authState.showMessage('Verification email sent! Please check your inbox.');
      }
    } catch (e) {
      final authState = ref.read(authStateProvider.notifier);
      authState.showMessage('Failed to send verification email. Please try again.');
    }
  }

  void _invalidateUserProviders() {
    ref.invalidate(fetchAndCacheCourseProgressProvider);
    ref.invalidate(fetchAndCacheModuleProgressProvider);
    ref.invalidate(fetchAndCacheLessonProgressProvider);
    ref.invalidate(activeCourseWithDetailsProvider);
    ref.invalidate(upcomingCoursesWithDetailsProvider);
    ref.invalidate(completedCoursesWithDetailsProvider);
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