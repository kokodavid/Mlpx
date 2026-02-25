import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

// Service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// Profile state provider
final profileProvider =
StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService, ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final ProfileService _profileService;
  final Ref _ref;
  bool _hasListenerSetup = false;
  bool _mounted = true;
  bool _isLoading = false;
  String? _lastLoadedUserId;

  ProfileNotifier(this._profileService, this._ref)
      : super(const AsyncValue.loading()) {
    _setupAuthListener();
    _loadInitialProfile();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setupAuthListener() {
    if (_hasListenerSetup) return;
    _hasListenerSetup = true;

    _ref.listen<AsyncValue<User?>>(
      authProvider,
          (previous, next) {
        next.when(
          data: (user) {
            final previousUser = previous?.value;
            if (user?.id != previousUser?.id &&
                user?.id != _lastLoadedUserId) {
              if (user != null) {
                Future.microtask(() => loadProfile());
              } else {
                _lastLoadedUserId = null;
                if (_mounted) state = const AsyncValue.data(null);
              }
            }
          },
          loading: () {},
          error: (_, __) {
            if (_mounted) state = const AsyncValue.data(null);
          },
        );
      },
    );
  }

  void _loadInitialProfile() {
    final authState = _ref.read(authProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          loadProfile();
        } else {
          if (_mounted) state = const AsyncValue.data(null);
        }
      },
      loading: () {
        if (_mounted) state = const AsyncValue.loading();
      },
      error: (_, __) {
        if (_mounted) state = const AsyncValue.data(null);
      },
    );
  }

  Future<void> loadProfile() async {
    if (_isLoading) return;

    final user = _ref.read(authProvider).value;
    if (user == null) {
      _lastLoadedUserId = null;
      if (_mounted) state = const AsyncValue.data(null);
      return;
    }

    if (_lastLoadedUserId == user.id && state.value != null) return;

    _isLoading = true;
    if (_mounted) state = const AsyncValue.loading();

    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (_mounted) {
        _lastLoadedUserId = user.id;
        state = AsyncValue.data(profile);
      }
    } catch (error, stackTrace) {
      if (_mounted) state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> forceRefresh() async {
    _lastLoadedUserId = null;
    await loadProfile();
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      final success = await _profileService.updateProfile(profile);
      if (success && _mounted) state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      if (_mounted) state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAvatar(String imagePath) async {
    try {
      final imageUrl = await _profileService.updateAvatar(imagePath);
      if (imageUrl != null && _mounted) {
        final currentProfile = state.value;
        if (currentProfile != null) {
          state = AsyncValue.data(currentProfile.copyWith(avatarUrl: imageUrl));
        }
      }
    } catch (error, stackTrace) {
      if (_mounted) state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _profileService.signOut();
      _lastLoadedUserId = null;
      if (_mounted) state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      if (_mounted) state = AsyncValue.error(error, stackTrace);
    }
  }
}