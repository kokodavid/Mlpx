import 'package:hive/hive.dart';

part 'course_model.g.dart';

@HiveType(typeId: 3)
class CourseModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime? createdAt;
  @HiveField(4)
  final DateTime? updatedAt;
  @HiveField(5)
  final int durationInMinutes;
  @HiveField(6)
  final String? soundUrlPreview;
  @HiveField(7)
  final String? soundUrlDetail;
  @HiveField(8)
  final bool locked;
  @HiveField(9)
  final int level;
  @HiveField(10)
  final String? type;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    this.createdAt,
    this.updatedAt,
    required this.durationInMinutes,
    this.soundUrlPreview,
    this.soundUrlDetail,
    required this.locked,
    required this.level,
    this.type,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        durationInMinutes: json['duration_in_minutes'] as int,
        soundUrlPreview: json['sound_url_overview'] as String?,
        soundUrlDetail: json['sound_url_detail'] as String?,
        locked: json['locked'] as bool,
        level: json['level'] as int,
        type: json['type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'duration_in_minutes': durationInMinutes,
        'sound_url_overview': soundUrlPreview,
        'sound_url_detail': soundUrlDetail,
        'locked': locked,
        'level': level,
        'type': type,
      };
}
