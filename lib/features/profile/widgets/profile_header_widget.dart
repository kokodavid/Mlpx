import 'package:flutter/material.dart';
import '../../../features/subscription/plan_type.dart';
import '../../../utils/app_colors.dart';
import '../models/profile_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final ProfileModel? profile;
  final PlanType planType;

  const ProfileHeaderWidget({
    super.key,
    this.profile,
    this.planType = PlanType.free,
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
        const SizedBox(height: 14),

        // Plan badge
        _PlanBadge(planType: planType),
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

class _PlanBadge extends StatelessWidget {
  final PlanType planType;
  const _PlanBadge({required this.planType});

  @override
  Widget build(BuildContext context) {
    final (icon, label, bg, fg) = switch (planType) {
      PlanType.premium => (
          Icons.workspace_premium_rounded,
          'Premium',
          const Color(0xFFFFF1E6),
          const Color(0xFFE85D04),
        ),
      PlanType.sponsored => (
          Icons.card_giftcard_rounded,
          'Sponsored',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      PlanType.free => (
          Icons.person_outline_rounded,
          'Free Plan',
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}