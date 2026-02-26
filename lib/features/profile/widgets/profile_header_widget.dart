import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../models/profile_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final ProfileModel? profile;

  const ProfileHeaderWidget({
    super.key,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : profile?.email ?? 'User';
    final email = profile?.email ?? 'No email available';

    return Column(
      children: [
        // Avatar — no edit badge
        CircleAvatar(
          radius: 52,
          backgroundColor: AppColors.primaryColor.withOpacity(0.15),
          backgroundImage: (profile?.avatarUrl != null &&
              profile!.avatarUrl!.isNotEmpty)
              ? NetworkImage(profile!.avatarUrl!)
              : null,
          child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
              ? Text(
            _initials(fullName),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          )
              : null,
        ),
        const SizedBox(height: 12),

        // Full name
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.copBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          email,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}