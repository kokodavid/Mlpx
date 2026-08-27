import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_download_provider.dart';
import 'package:milpress/features/course/widgets/course_download_success_bottom_sheet.dart';
import 'package:milpress/utils/app_colors.dart';

Future<void> showCourseDownloadBottomSheet({
  required BuildContext context,
  required String courseId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CourseDownloadBottomSheet(courseId: courseId),
  );
}

class CourseDownloadBottomSheet extends ConsumerWidget {
  final String courseId;

  const CourseDownloadBottomSheet({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(courseV2DownloadProvider(courseId));

    if (downloadState.isDownloaded) {
      return CourseDownloadSuccessBottomSheet(
        downloadedBytes: downloadState.downloadedBytes,
      );
    }

    if (downloadState.isLoading) {
      return _DownloadingCourseSheet(
        downloadedBytes: downloadState.downloadedBytes,
        downloadedLessons: downloadState.downloadedLessons,
        estimatedTotalBytes: downloadState.estimatedTotalBytes,
        isCancelling: downloadState.isCancelling,
        totalLessons: downloadState.totalLessons,
        onContinueInBackground: () => Navigator.of(context).pop(),
        onCancelDownload: () => ref
            .read(courseV2DownloadProvider(courseId).notifier)
            .cancelDownload(),
      );
    }

    final estimatedBytes = downloadState.downloadedBytes > 0
        ? downloadState.downloadedBytes
        : downloadState.totalLessons * 3 * 1024 * 1024;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        28,
        22,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_download_outlined,
                color: AppColors.primaryColor,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Download Course\nfor Offline Learning',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.copBlue,
              fontSize: 23,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Save all modules, lessons, audio, and activities so you can keep learning without an internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.lightGrey2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _CourseDownloadInfoRow(
                  icon: Icons.layers_outlined,
                  iconColor: AppColors.primaryColor,
                  iconBackgroundColor: AppColors.accentColor,
                  text: '${downloadState.totalLessons} lessons',
                ),
                const SizedBox(height: 18),
                _CourseDownloadInfoRow(
                  icon: Icons.file_download_outlined,
                  iconColor: AppColors.primaryColor,
                  iconBackgroundColor: AppColors.accentColor,
                  text: 'Estimated size - ${_formatMegabytes(estimatedBytes)}',
                ),
                const SizedBox(height: 18),
                const _CourseDownloadInfoRow(
                  icon: Icons.wifi_off_outlined,
                  iconColor: AppColors.successColor,
                  iconBackgroundColor: AppColors.sandyLight,
                  text: 'Available offline anytime',
                ),
                const SizedBox(height: 18),
                const _CourseDownloadInfoRow(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.successColor,
                  iconBackgroundColor: AppColors.sandyLight,
                  text: 'Progress syncs when you reconnect',
                ),
              ],
            ),
          ),
          if (downloadState.isError && downloadState.error != null) ...[
            const SizedBox(height: 12),
            Text(
              downloadState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: downloadState.isLoading
                ? null
                : () => ref
                    .read(courseV2DownloadProvider(courseId).notifier)
                    .downloadCourse(),
            icon: downloadState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.backgroundColor,
                    ),
                  )
                : const Icon(Icons.file_download_outlined, size: 18),
            label: Text(
              downloadState.isLoading ? 'Downloading...' : 'Download Course',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              disabledBackgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.backgroundColor,
              disabledForegroundColor: AppColors.backgroundColor,
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
            onPressed: downloadState.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text(
              'Not Now',
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

class _DownloadingCourseSheet extends StatelessWidget {
  final int downloadedBytes;
  final int downloadedLessons;
  final int estimatedTotalBytes;
  final bool isCancelling;
  final int totalLessons;
  final VoidCallback onContinueInBackground;
  final VoidCallback onCancelDownload;

  const _DownloadingCourseSheet({
    required this.downloadedBytes,
    required this.downloadedLessons,
    required this.estimatedTotalBytes,
    required this.isCancelling,
    required this.totalLessons,
    required this.onContinueInBackground,
    required this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    final safeEstimatedBytes = estimatedTotalBytes <= 0
        ? totalLessons * 3 * 1024 * 1024
        : estimatedTotalBytes;
    final progress = safeEstimatedBytes <= 0
        ? 0.0
        : (downloadedBytes / safeEstimatedBytes).clamp(0.0, 0.99);
    final percentage = (progress * 100).round();
    final remainingLessons = totalLessons - downloadedLessons;
    final remainingSeconds = remainingLessons <= 0 ? 1 : remainingLessons * 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        28,
        22,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Downloading Course',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.copBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Downloading lessons, audio, and learning materials...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      backgroundColor: AppColors.lightGrey,
                      color: AppColors.primaryColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: AppColors.copBlue,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatMegabytes(downloadedBytes)} of ${_formatMegabytes(safeEstimatedBytes)}',
                        style: const TextStyle(
                          color: AppColors.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            isCancelling
                ? 'Canceling after the current lesson...'
                : 'About $remainingSeconds seconds remaining',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greyText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onContinueInBackground,
            icon: const Icon(Icons.arrow_circle_down_outlined),
            label: const Text('Continue in background'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.lightGrey2,
              foregroundColor: AppColors.copBlue,
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: isCancelling ? null : onCancelDownload,
            child: Text(
              isCancelling ? 'Canceling download' : 'Cancel download',
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.greyText,
                size: 16,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'You can keep using the app while this downloads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

class _CourseDownloadInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String text;

  const _CourseDownloadInfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.copBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
