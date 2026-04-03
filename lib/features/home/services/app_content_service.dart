import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_content_model.dart';
import '../models/app_resource_model.dart';

class AppContentService {
  final SupabaseClient _supabase;

  AppContentService(this._supabase);

  Future<AppContent> fetchAppContent() async {
    try {
      final data = await _supabase
          .from('app_content')
          .select()
          .eq('id', 1)
          .single();
      return AppContent.fromMap(data);
    } catch (e) {
      throw Exception('Failed to fetch app content: $e');
    }
  }

  Future<List<AppResource>> fetchResources() async {
    try {
      final List data = await _supabase
          .from('app_resources')
          .select()
          .order('display_order', ascending: true);
      return data
          .map((e) => AppResource.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch app resources: $e');
    }
  }
}
