import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:milpress/providers/connectivity_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'profile_offline_storage_service.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileOfflineStorageService _offlineStorageService =
      ProfileOfflineStorageService();
  final Connectivity _connectivity = Connectivity();

  /// Get current user's profile data
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final connectivityResult = await _connectivity.checkConnectivity();
      if (isOfflineResult(connectivityResult)) {
        return _offlineStorageService.readProfile();
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response != null) {
        final profile = ProfileModel.fromJson({
          ...response,
          'id': user.id,
          'email': user.email,
        });
        await _offlineStorageService.saveProfile(profile);
        return profile;
      }

      final names = _splitFullName(user.userMetadata?['full_name'] ?? '');
      final newProfile = ProfileModel(
        id: user.id,
        firstName: names.$1,
        lastName: names.$2,
        email: user.email ?? '',
        avatarUrl: user.userMetadata?['avatar_url'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('profiles').upsert(newProfile.toJson());
      await _offlineStorageService.saveProfile(newProfile);

      return newProfile;
    } catch (e) {
      print('Error fetching profile: $e');
      return _offlineStorageService.readProfile();
    }
  }

  /// Split a full name into first and last name
  (String, String) _splitFullName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts[0], '');
    return (parts[0], parts.sublist(1).join(' '));
  }

  /// Update user profile
  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('profiles')
          .upsert(profile.toJson())
          .eq('id', user.id);

      await _offlineStorageService.saveProfile(profile);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Update user avatar
  Future<String?> updateAvatar(String imagePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final fileExt = imagePath.split('.').last;
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await _supabase.storage
          .from('avatars')
          .upload(filePath, File(imagePath));

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      final cachedProfile = await _offlineStorageService.readProfile();
      if (cachedProfile != null) {
        await _offlineStorageService.saveProfile(
          cachedProfile.copyWith(avatarUrl: imageUrl),
        );
      }

      return imageUrl;
    } catch (e) {
      print('Error updating avatar: $e');
      return null;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
