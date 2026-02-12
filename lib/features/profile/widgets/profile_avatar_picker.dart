import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class ProfileAvatarPicker extends StatelessWidget {
  /// Remote or local file URL for the avatar. Null shows initials fallback.
  final String? avatarUrl;

  /// Initials shown when no avatar is available, e.g. "JD".
  final String initials;

  /// Called when the user taps the edit overlay. Handle image picking here.
  final VoidCallback onTap;

  /// Whether to show the loading spinner (e.g. while uploading).
  final bool isLoading;

  const ProfileAvatarPicker({
    super.key,
    this.avatarUrl,
    required this.initials,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Avatar rounded rectangle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primaryColor.withOpacity(0.15),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildAvatarContent(),
            ),
          ),

          // Edit overlay badge
          if (!isLoading)
            Positioned.fill(
              bottom: 0,
              right: 0,

              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 30,
                  height: 30,

                  child: const Icon(
                    Icons.draw_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (isLoading)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Local file path (picked from device before upload)
    if (avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        !avatarUrl!.startsWith('http')) {
      return Image.file(
        File(avatarUrl!),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }

    // Remote network URL
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }

    // No URL — show initials
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.15),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials.toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,

          ),
        ),
      ),
    );
  }
}