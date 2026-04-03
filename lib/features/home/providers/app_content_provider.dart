import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_content_model.dart';
import '../models/app_resource_model.dart';
import '../services/app_content_service.dart';

final _appContentServiceProvider = Provider<AppContentService>((ref) {
  return AppContentService(Supabase.instance.client);
});

final appContentProvider = FutureProvider<AppContent>((ref) async {
  return ref.watch(_appContentServiceProvider).fetchAppContent();
});

final appResourcesProvider = FutureProvider<List<AppResource>>((ref) async {
  return ref.watch(_appContentServiceProvider).fetchResources();
});
