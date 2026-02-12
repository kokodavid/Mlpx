import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/edit_profile_model.dart';
import '../models/profile_model.dart';
import '../services/edit_profile_service.dart';
import 'profile_provider.dart';

// Service provider
final editProfileServiceProvider = Provider<EditProfileService>((ref) {
  return EditProfileService();
});

// Edit profile state provider
final editProfileProvider =
StateNotifierProvider<EditProfileNotifier, EditProfileModel>((ref) {
  final service = ref.watch(editProfileServiceProvider);
  final profileAsync = ref.watch(profileProvider);

  // Pre-fill from the existing loaded profile
  final initialState = profileAsync.value != null
      ? EditProfileModel.fromProfile(profileAsync.value!)
      : const EditProfileModel();

  return EditProfileNotifier(service, ref, initialState);
});

class EditProfileNotifier extends StateNotifier<EditProfileModel> {
  final EditProfileService _service;
  final Ref _ref;

  EditProfileNotifier(this._service, this._ref, EditProfileModel initialState)
      : super(initialState);

  /// Update the first name field in state
  void setFirstName(String value) {
    state = state.copyWith(
      firstName: value,
      clearError: true,
      isSuccess: false,
    );
  }

  /// Update the last name field in state
  void setLastName(String value) {
    state = state.copyWith(
      lastName: value,
      clearError: true,
      isSuccess: false,
    );
  }

  /// Set a new local avatar path (before upload)
  void setAvatarUrl(String? url) {
    state = state.copyWith(avatarUrl: url, clearError: true);
  }

  /// Submit the updated profile to Supabase and refresh the profile provider
  Future<void> submitProfile() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'First name and last name are required.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      final success = await _service.updateProfileDetails(
        firstName: state.firstName,
        lastName: state.lastName,
      );

      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update profile. Please try again.',
        );
        return;
      }

      // Force refresh the profile provider to fetch the latest data
      await _ref.read(profileProvider.notifier).forceRefresh();

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Upload a new avatar image, then refresh the profile provider
  Future<void> uploadAvatar(String imagePath) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final imageUrl = await _service.uploadAvatar(imagePath);

      if (imageUrl == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload image. Please try again.',
        );
        return;
      }

      // Update local state with new URL
      state = state.copyWith(isLoading: false, avatarUrl: imageUrl);

      // Also sync avatar into profileProvider so the profile page updates
      _ref.read(profileProvider.notifier).updateAvatar(imagePath);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during upload.',
      );
    }
  }

  /// Reset the state back to the values from the loaded profile
  void resetToCurrentProfile() {
    final profile = _ref.read(profileProvider).value;
    if (profile != null) {
      state = EditProfileModel.fromProfile(profile);
    }
  }

  /// Clear any error message shown in the UI
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}