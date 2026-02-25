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

      await _supabase.from('profiles').update({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating profile details: $e');
      return false;
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