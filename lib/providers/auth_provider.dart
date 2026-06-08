import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/course/providers/course_provider.dart';
import '../features/subscription/plan_type.dart';
import '../models/profile.dart';
import '../utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/user_progress/providers/course_progress_providers.dart';
import '../features/user_progress/providers/user_progress_providers.dart';

class AuthState {
  final User? user;
  final Profile? profile;
  final String? message;
  final bool isLoading;
  final bool isEmailVerified;
  final bool isGuestUser;

  AuthState({
    this.user,
    this.profile,
    this.message,
    this.isLoading = false,
    this.isEmailVerified = false,
    this.isGuestUser = false,
  });

  PlanType get planType => profile?.planType ?? PlanType.free;

  AuthState copyWith({
    User? user,
    Profile? profile,
    String? message,
    bool? isLoading,
    bool? isEmailVerified,
    bool? isGuestUser,
  }) {
    return AuthState(
      user:            user            ?? this.user,
      profile:         profile         ?? this.profile,
      message:         message         ?? this.message,
      isLoading:       isLoading       ?? this.isLoading,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isGuestUser:     isGuestUser     ?? this.isGuestUser,
    );
  }
}

final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  RealtimeChannel? _profileChannel;

  AuthStateNotifier(this._ref) : super(AuthState()) {
    _initializeGuestMode();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
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
        // Redeem any pending invites/grants for this email, then load profile
        await _redeemPendingInvites(user);
        final profile = await _fetchProfile(user.id);
        state = state.copyWith(
          user: user,
          profile: profile,
          isEmailVerified: isEmailVerified,
          isGuestUser: false,
        );
        // Force profileProvider to re-fetch so it reflects the latest
        // plan_type (e.g. after an org invite is redeemed on sign-in).
        _ref.read(profileRefreshProvider.notifier).state++;
        // Start listening for real-time plan_type changes (org removal etc.)
        _subscribeToProfileChanges(user.id);
      } else {
        _profileChannel?.unsubscribe();
        _profileChannel = null;
        state = state.copyWith(
          user: null,
          profile: null,
          isEmailVerified: false,
          isGuestUser: state.isGuestUser,
        );
      }
    });
  }

  /// Fetches the profile row for [userId], returns null on error.
  Future<Profile?> _fetchProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return Profile.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      log('_fetchProfile error: $e');
      return null;
    }
  }

  /// Links any pending org_members / sponsored_grants rows whose invite_email
  /// matches this user's email, then recomputes plan_type — all via a
  /// SECURITY DEFINER RPC that bypasses RLS (direct table updates are blocked
  /// by admin-only policies on org_members and sponsored_grants).
  Future<void> _redeemPendingInvites(User user) async {
    final email = user.email;
    if (email == null) return;
    try {
      await SupabaseConfig.client.rpc(
        'redeem_pending_invites',
        params: {
          'p_user_id': user.id,
          'p_email':   email.toLowerCase(),
        },
      );
    } catch (e) {
      // Non-fatal — user still signs in; plan just stays free until next load
      log('_redeemPendingInvites error: $e');
    }
  }

  /// Refreshes the stored profile (e.g. after a plan change).
  Future<void> refreshProfile() async {
    final userId = state.user?.id;
    if (userId == null) return;
    final profile = await _fetchProfile(userId);
    if (profile != null) state = state.copyWith(profile: profile);
  }

  /// Subscribes to Realtime changes on this user's profiles row.
  /// When plan_type changes remotely (org removal, grant revocation),
  /// the app reflects the new plan immediately without requiring sign-out.
  void _subscribeToProfileChanges(String userId) {
    // Cancel any existing subscription first
    _profileChannel?.unsubscribe();

    _profileChannel = SupabaseConfig.client
        .channel('profile:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) async {
            final newPlanType = PlanType.fromString(
              payload.newRecord['plan_type'] as String?,
            );
            final currentPlanType = state.profile?.planType ?? PlanType.free;

            // Only act if plan_type actually changed
            if (newPlanType != currentPlanType) {
              log('Plan type changed remotely: $currentPlanType → $newPlanType');
              final profile = await _fetchProfile(userId);
              if (profile != null && mounted) {
                state = state.copyWith(profile: profile);
                _ref.read(profileRefreshProvider.notifier).state++;
              }
            }
          },
        )
        .subscribe();
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

        // Redeem invites then refresh profile in AuthState
        await ref.read(authStateProvider.notifier)
            ._redeemPendingInvites(response.user!);
        await ref.read(authStateProvider.notifier).refreshProfile();

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

        // Redeem invites then refresh profile in AuthState
        await ref.read(authStateProvider.notifier)
            ._redeemPendingInvites(response.user!);
        await ref.read(authStateProvider.notifier).refreshProfile();

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

// ── Subscription helpers ───────────────────────────────────────────────────

/// The current user's loaded Profile, or null if not signed in.
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authStateProvider).profile;
});

/// The current user's effective plan type. Defaults to free for guests /
/// unauthenticated users. Any widget can watch this to gate premium content.
final currentPlanProvider = Provider<PlanType>((ref) {
  return ref.watch(authStateProvider).planType;
});

/// True when the current user has premium or sponsored access.
final hasPremiumAccessProvider = Provider<bool>((ref) {
  return ref.watch(currentPlanProvider).hasPremiumAccess;
});

/// Incremented by AuthStateNotifier after _redeemPendingInvites completes.
/// profileProvider watches this to know when to force-refresh.
final profileRefreshProvider = StateProvider<int>((_) => 0);