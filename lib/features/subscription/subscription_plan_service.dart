import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'subscription_plan_model.dart';

// =============================================================================
// SubscriptionPlanService — fetches active plans from the DB
// =============================================================================
class SubscriptionPlanService {
  final SupabaseClient _client;
  SubscriptionPlanService(this._client);

  /// Returns all active plans ordered by sort_order, with their features.
  Future<List<SubscriptionPlan>> fetchActivePlans() async {
    final List data = await _client
        .from('subscription_plans')
        .select('*, plan_features(*)')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return data
        .map((e) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

// =============================================================================
// Providers
// =============================================================================
final subscriptionPlanServiceProvider = Provider<SubscriptionPlanService>((ref) {
  return SubscriptionPlanService(Supabase.instance.client);
});

/// All active subscription plans — used to render the paywall.
final activePlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(subscriptionPlanServiceProvider).fetchActivePlans();
});
