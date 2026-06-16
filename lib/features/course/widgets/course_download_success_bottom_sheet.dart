import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';

class CourseDownloadSuccessBottomSheet extends StatelessWidget {
  final int downloadedBytes;

  const CourseDownloadSuccessBottomSheet({
    super.key,
    required this.downloadedBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.successColor,
                  width: 12,
                ),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.successColor,
                size: 62,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Course Ready Offline',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.copBlue,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'All lessons, activities, and audio are downloaded and now available without an internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: AppColors.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stored on Device - ${_formatMegabytes(downloadedBytes)}',
                    style: const TextStyle(
                      color: AppColors.successColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/downloaded-lessons');
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start Learning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.backgroundColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMegabytes(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.ceil()} MB';
  }
}
