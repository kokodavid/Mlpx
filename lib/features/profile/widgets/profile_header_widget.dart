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
        // Avatar with stroke border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 6.0,
            ),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primaryColor.withOpacity(0.15),
            backgroundImage: (profile?.avatarUrl != null &&
                profile!.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                ? Text(
              _initials(fullName),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            )
                : null,
          ),
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
        const SizedBox(height: 6),

        // Email inside white rounded pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
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