import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://bdlfghvrbjjzybuexdwe.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkbGZnaHZyYmpqenlidWV4ZHdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3Mjg3MzEsImV4cCI6MjA3NDMwNDczMX0.Mv9FL54DFsa3AqQNPU7sLhTLzWY-ck31JwrMAElghio';

  static late final ProfileService profileService;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,

      ),

      debug: true,
    );

    profileService = ProfileService(client);

    // Log initial auth state
    final session = client.auth.currentSession;
    print('Supabase initialized. Current session: ${session?.user?.email}, verified: ${session?.user?.emailConfirmedAt}');
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: data,
      // IMPORTANT: This tells Supabase where to redirect after email verification
      emailRedirectTo: 'io.supabase.milpress://email-callback/',
    );

    if (response.user != null) {
      await profileService.createProfile(
        userId: response.user!.id,
        email: email,
        fullName: data?['full_name'],
        avatarUrl: data?['avatar_url'],
      );
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static User? get currentUser => client.auth.currentUser;
}