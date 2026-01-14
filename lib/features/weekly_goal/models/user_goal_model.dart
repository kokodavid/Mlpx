class UserGoalModel {
  static const String lessonsPerWeekGoalType = 'lessons_per_week';

  final String id;
  final String userId;
  final String goalType;
  final int goalValue;
  final String timezone;
  final int weekStart;
  final DateTime activeFrom;
  final DateTime? activeUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGoalModel({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.goalValue,
    required this.timezone,
    required this.weekStart,
    required this.activeFrom,
    this.activeUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGoalModel.fromJson(Map<String, dynamic> json) {
    return UserGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      goalValue: json['goal_value'] as int,
      timezone: json['timezone'] as String,
      weekStart: json['week_start'] as int? ?? 1,
      activeFrom: DateTime.parse(json['active_from'] as String),
      activeUntil: json['active_until'] != null
          ? DateTime.parse(json['active_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'goal_value': goalValue,
      'timezone': timezone,
      'week_start': weekStart,
      'active_from': activeFrom.toIso8601String(),
      'active_until': activeUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
