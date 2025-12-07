import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';
import '../models/profile_model.dart';

class ProfileHeaderWidget extends ConsumerWidget {
  final ProfileModel? profile;
  final VoidCallback? onEditProfile;

  const ProfileHeaderWidget({
    super.key,
    this.profile,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/turtle.png'),
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName.isNotEmpty == true 
                ? profile!.fullName 
                : profile?.email ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.copBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            profile?.email ?? 'No email available',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          // const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: onEditProfile,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primaryColor,
          //       foregroundColor: Colors.white,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //     ),
          //     child: const Text(
          //       'Edit Profile',
          //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
} 