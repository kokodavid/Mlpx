import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

// Service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// Profile state provider
final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService);
});

// User stats provider
final userStatsProvider = StateNotifierProvider<UserStatsNotifier, AsyncValue<Map<String, int>>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return UserStatsNotifier(profileService);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _profileService.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      final success = await _profileService.updateProfile(profile);
      if (success) {
        state = AsyncValue.data(profile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAvatar(String imagePath) async {
    try {
      final imageUrl = await _profileService.updateAvatar(imagePath);
      if (imageUrl != null && state.value != null) {
        final updatedProfile = state.value!.copyWith(avatarUrl: imageUrl);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _profileService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class UserStatsNotifier extends StateNotifier<AsyncValue<Map<String, int>>> {
  final ProfileService _profileService;

  UserStatsNotifier(this._profileService) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _profileService.getUserStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }
} 