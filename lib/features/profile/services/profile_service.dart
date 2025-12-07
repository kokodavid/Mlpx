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

      // Get profile data from profiles table
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

      // If no profile exists, create a basic one from user data
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

      // Create the profile in the database
      await _supabase
          .from('profiles')
          .upsert(newProfile.toJson());

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

  /// Get user statistics from Supabase tables
  Future<Map<String, int>> getUserStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      // Get courses completed
      final coursesResponse = await _supabase
          .from('course_progress')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_completed', true);

      // Get lessons completed
      final lessonsResponse = await _supabase
          .from('lesson_progress')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'completed');

      // Get modules completed
      final modulesResponse = await _supabase
          .from('module_progress')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'completed');

      return {
        'courses_completed': coursesResponse.length,
        'lessons_completed': lessonsResponse.length,
        'modules_completed': modulesResponse.length,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {
        'courses_completed': 0,
        'lessons_completed': 0,
        'modules_completed': 0,
      };
    }
  }

  /// Update user avatar
  Future<String?> updateAvatar(String imagePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final fileExt = imagePath.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload image to storage
      await _supabase.storage
          .from('avatars')
          .upload(filePath, File(imagePath));

      // Get public URL
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update profile with new avatar URL
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

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Delete user data from profiles table
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', user.id);

      // Delete user from auth
      await _supabase.auth.admin.deleteUser(user.id);

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
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