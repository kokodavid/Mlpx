import 'package:flutter/material.dart';
import 'package:milpress/features/home/course_preview_tile.dart';
import 'package:milpress/utils/app_colors.dart';

class HomeCourseTile extends StatelessWidget {
  final String title;
  final String courseLabel;
  final String levelLabel;
  final String introductionTitle;
  final String previewText;
  final bool allLessonsComplete;
  final bool allAssessmentsComplete;
  final VoidCallback? onTap;
  final String previewUrl;
  final String previewSourceId;
  final EdgeInsetsGeometry margin;

  const HomeCourseTile({
    super.key,
    required this.title,
    required this.courseLabel,
    required this.levelLabel,
    required this.previewUrl,
    required this.previewSourceId,
    this.introductionTitle = 'Introduction Audio',
    this.previewText = 'Tap to preview this course',
    this.allLessonsComplete = false,
    this.allAssessmentsComplete = false,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 18),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10131A),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _MetaPill(
                icon: Icons.school_outlined,
                text: courseLabel,
                borderColor: AppColors.primaryColor,
                foregroundColor: AppColors.primaryColor,
              ),
              _MetaPill(
                text: levelLabel.toUpperCase(),
                borderColor: const Color(0xFFDCD7CF),
                foregroundColor: const Color(0xFF7B7B7B),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CoursePreviewTile(
            url: previewUrl,
            sourceId: previewSourceId,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
              color: const Color(0xFFF5F5F5),
            ),
            child: Column(
              children: [
                _CompletionRow(
                  label: 'All Lessons Complete',
                  isComplete: allLessonsComplete,
                ),
                const SizedBox(height: 10),
                _CompletionRow(
                  label: 'All Assessments Complete',
                  isComplete: allAssessmentsComplete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRow extends StatelessWidget {
  final String label;
  final bool isComplete;

  const _CompletionRow({required this.label, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? AppColors.successColor : Colors.transparent,
            border: isComplete
                ? null
                : Border.all(
                    color: const Color(0xFFDCD7CF),
                    width: 1.5,
                  ),
          ),
          child: isComplete
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isComplete
                ? const Color(0xFF10131A)
                : const Color(0xFF7B7B7B),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color borderColor;
  final Color foregroundColor;

  const _MetaPill({
    this.icon,
    required this.text,
    required this.borderColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
