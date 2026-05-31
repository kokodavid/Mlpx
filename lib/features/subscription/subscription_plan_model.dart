import 'plan_type.dart';

// =============================================================================
// SubscriptionPlanFeature — one bullet point on a plan card
// =============================================================================
class SubscriptionPlanFeature {
  final String id;
  final String label;
  final bool isIncluded;
  final int sortOrder;

  const SubscriptionPlanFeature({
    required this.id,
    required this.label,
    required this.isIncluded,
    required this.sortOrder,
  });

  factory SubscriptionPlanFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanFeature(
      id:         json['id'] as String,
      label:      json['label'] as String,
      isIncluded: (json['is_included'] as bool?) ?? true,
      sortOrder:  (json['sort_order'] as int?) ?? 0,
    );
  }
}

// =============================================================================
// SubscriptionPlan — one purchasable package shown on the paywall
// =============================================================================
class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final PlanType planType;
  final String billingCycle;   // 'monthly' | 'annual'
  final double priceUsd;
  final bool isHighlighted;
  final int sortOrder;
  final String? stripePriceId;
  final String? rcProductId;
  final List<SubscriptionPlanFeature> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.planType,
    required this.billingCycle,
    required this.priceUsd,
    required this.isHighlighted,
    required this.sortOrder,
    this.stripePriceId,
    this.rcProductId,
    this.features = const [],
  });

  bool get isFree => priceUsd == 0;

  String get formattedPrice =>
      priceUsd == 0 ? 'Free' : '\$${priceUsd.toStringAsFixed(2)}';

  String get billingLabel {
    if (priceUsd == 0) return 'Forever free';
    return billingCycle == 'annual' ? '/ year' : '/ month';
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['plan_features'] as List?;
    final features = (rawFeatures ?? [])
        .map((f) => SubscriptionPlanFeature.fromJson(
              Map<String, dynamic>.from(f as Map),
            ))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SubscriptionPlan(
      id:            json['id'] as String,
      name:          json['name'] as String,
      description:   json['description'] as String?,
      planType:      PlanType.fromString(json['plan_type'] as String?),
      billingCycle:  (json['billing_cycle'] as String?) ?? 'monthly',
      priceUsd:      (json['price_usd'] as num?)?.toDouble() ?? 0,
      isHighlighted: (json['is_highlighted'] as bool?) ?? false,
      sortOrder:     (json['sort_order'] as int?) ?? 0,
      stripePriceId: json['stripe_price_id'] as String?,
      rcProductId:   json['rc_product_id'] as String?,
      features:      features,
    );
  }
}
