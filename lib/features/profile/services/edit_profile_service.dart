import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class EditProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update the current user's first and last name in the profiles table
  Future<bool> updateProfileDetails({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('profiles')
          .update({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating profile details: $e');
      return false;
    }
  }

  /// Upload a new avatar image and return the public URL
  Future<String?> uploadAvatar(String imagePath) async {
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

      // Persist the new avatar URL to the profiles table
      await _supabase
          .from('profiles')
          .update({
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', user.id);

      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  /// Send a password reset email to the given address via Supabase Auth
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  /// Fetch the current user's latest profile from the database
  Future<ProfileModel?> getUpdatedProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ProfileModel.fromJson({
        ...response,
        'id': user.id,
        'email': user.email,
      });
    } catch (e) {
      print('Error fetching updated profile: $e');
      return null;
    }
  }
}