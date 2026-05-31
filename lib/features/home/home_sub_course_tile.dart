import 'package:flutter/material.dart';
import 'package:milpress/shared/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';

class HomeSubCourseTile extends StatelessWidget {
  final int modulesCount;
  final int lessonsCount;
  final bool isEligible;
  final bool allowLockedAccessOverride;
  final String eligibilityText;
  final String buttonText;
  final bool isCompleted;
  final bool isPremiumLocked;
  final VoidCallback? onStartCourse;
  final VoidCallback? onReviewCourse;
  final VoidCallback? onRestartCourse;
  final VoidCallback? onUnlockPremium;
  final EdgeInsetsGeometry margin;

  const HomeSubCourseTile({
    super.key,
    required this.modulesCount,
    required this.lessonsCount,
    this.isEligible = true,
    this.allowLockedAccessOverride = false,
    this.eligibilityText = 'You are eligible to start this level',
    this.buttonText = 'Start Course',
    this.isCompleted = false,
    this.isPremiumLocked = false,
    this.onStartCourse,
    this.onReviewCourse,
    this.onRestartCourse,
    this.onUnlockPremium,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNoLessons =
        !allowLockedAccessOverride && !isCompleted && lessonsCount == 0;
    final eligibilityColor =
        isEligible ? const Color(0xFF6AA84F) : AppColors.textColor;
    final iconBackground =
        isEligible ? const Color(0xFFDDE9D6) : const Color(0xFFE7E7E7);

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _InfoPill(
                icon: Icons.auto_stories_outlined,
                label: '$modulesCount Modules',
              ),
              _InfoPill(
                icon: Icons.menu_book_outlined,
                label: '$lessonsCount Lessons',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCompleted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.successColor,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'All module completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Review Course',
                    onPressed: onReviewCourse ?? () {},
                    isFullWidth: true,
                    isPrimary: true,
                    height: 48,
                    backgroundColor: AppColors.successColor,
                    textColor: Colors.white,
                    fontSize: 16,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onRestartCourse,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(
                        color: AppColors.successColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Icon(
                      Icons.replay_rounded,
                      color: AppColors.successColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isPremiumLocked) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_rounded, color: Color(0xFFE85D04), size: 16),
                SizedBox(width: 6),
                Text(
                  'Premium course — upgrade to access',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE85D04),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUnlockPremium,
                icon: const Icon(Icons.lock_open_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  'Unlock Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D04),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            if (hasNoLessons)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Lessons coming soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else if (allowLockedAccessOverride && lessonsCount == 0)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bug_report_outlined,
                      color: AppColors.primaryColor, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Debug override enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: eligibilityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      eligibilityText,
                      style: TextStyle(
                        fontSize: 12,
                        color: eligibilityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: buttonText,
                onPressed:
                    (isEligible && !hasNoLessons && onStartCourse != null)
                        ? onStartCourse!
                        : () {},
                isFullWidth: true,
                isPrimary: true,
                height: 48,
                backgroundColor: (isEligible && !hasNoLessons)
                    ? AppColors.primaryColor
                    : AppColors.textColor,
                textColor: Colors.white,
                fontSize: 16,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF7A7A7A),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C6C6C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
