import '../features/subscription/plan_type.dart';

extension _StringNullIfEmpty on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}

class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Current effective plan — kept in sync by DB triggers.
  /// Defaults to free for any user who has no active subscription.
  final PlanType planType;

  /// Set when the user belongs to an organisation.
  final String? orgId;

  /// Set when the user's premium access is sponsored by an org.
  final String? sponsoredBy;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.planType = PlanType.free,
    this.orgId,
    this.sponsoredBy,
  });

  /// Convenience getters
  bool get hasPremiumAccess => planType.hasPremiumAccess;
  bool get isPremium        => planType.isPremium;
  bool get isSponsored      => planType.isSponsored;
  bool get isFree           => planType.isFree;

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Support both full_name (legacy) and first_name/last_name columns
    final fullName = json['full_name'] as String? ??
        [json['first_name'], json['last_name']]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ')
            .nullIfEmpty();

    return Profile(
      id:          json['id'] as String,
      email:       (json['email'] as String?) ?? '',
      fullName:    fullName,
      avatarUrl:   json['avatar_url'] as String?,
      createdAt:   DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:   DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      planType:    PlanType.fromString(json['plan_type'] as String?),
      orgId:       json['org_id'] as String?,
      sponsoredBy: json['sponsored_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'email':       email,
      'full_name':   fullName,
      'avatar_url':  avatarUrl,
      'created_at':  createdAt.toIso8601String(),
      'updated_at':  updatedAt.toIso8601String(),
      'plan_type':   planType.dbValue,
      if (orgId       != null) 'org_id':       orgId,
      if (sponsoredBy != null) 'sponsored_by': sponsoredBy,
    };
  }

  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    PlanType? planType,
    String? orgId,
    String? sponsoredBy,
  }) {
    return Profile(
      id:          id          ?? this.id,
      email:       email       ?? this.email,
      fullName:    fullName    ?? this.fullName,
      avatarUrl:   avatarUrl   ?? this.avatarUrl,
      createdAt:   createdAt   ?? this.createdAt,
      updatedAt:   updatedAt   ?? this.updatedAt,
      planType:    planType    ?? this.planType,
      orgId:       orgId       ?? this.orgId,
      sponsoredBy: sponsoredBy ?? this.sponsoredBy,
    );
  }
} 
