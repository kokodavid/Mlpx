import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<Profile> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return Profile.fromJson(response);
  }

  Future<void> createProfile({
    required String userId,
    required String email,
    String? fullName,
    String? avatarUrl,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  Future<void> deleteProfile(String userId) async {
    await _client
        .from('profiles')
        .delete()
        .eq('id', userId);
  }
} 
