// =============================================================================
// PlanType — mirrors the plan_type Postgres enum.
// Single source of truth for the learner app.
// =============================================================================
enum PlanType {
  free,
  premium,
  sponsored;

  /// Value stored in the database.
  String get dbValue {
    switch (this) {
      case PlanType.free:      return 'free';
      case PlanType.premium:   return 'premium';
      case PlanType.sponsored: return 'sponsored';
    }
  }

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case PlanType.free:      return 'Free';
      case PlanType.premium:   return 'Premium';
      case PlanType.sponsored: return 'Sponsored';
    }
  }

  bool get isPremium   => this == PlanType.premium;
  bool get isSponsored => this == PlanType.sponsored;
  bool get isFree      => this == PlanType.free;

  /// Whether this plan grants access to premium content.
  bool get hasPremiumAccess =>
      this == PlanType.premium || this == PlanType.sponsored;

  static PlanType fromString(String? value) {
    switch (value) {
      case 'premium':   return PlanType.premium;
      case 'sponsored': return PlanType.sponsored;
      default:          return PlanType.free;
    }
  }
}
