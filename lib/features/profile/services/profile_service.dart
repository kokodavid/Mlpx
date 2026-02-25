import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's profile data
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response != null) {
        return ProfileModel.fromJson({
          ...response,
          'id': user.id,
          'email': user.email,
        });
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

      return newProfile;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
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

      final imageUrl =
      _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

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