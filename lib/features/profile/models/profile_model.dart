class ProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int totalPoints;

  String get fullName => '$firstName $lastName'.trim();

  /// Returns true if all required fields are valid for submission
  bool get isValid =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.coursesCompleted = 0,
    this.lessonsCompleted = 0,
    this.totalPoints = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      coursesCompleted: json['courses_completed'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'courses_completed': coursesCompleted,
      'lessons_completed': lessonsCompleted,
      'total_points': totalPoints,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? coursesCompleted,
    int? lessonsCompleted,
    int? totalPoints,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coursesCompleted: coursesCompleted ?? this.coursesCompleted,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}