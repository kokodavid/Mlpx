import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonBottomActionBar extends StatelessWidget {
  final bool canGoBack;
  final bool isPrimaryEnabled;
  final String primaryLabel;
  final IconData? primaryIcon;
  final Color? primaryColor;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onBackPressed;

  const LessonBottomActionBar({
    super.key,
    required this.canGoBack,
    required this.isPrimaryEnabled,
    required this.primaryLabel,
    this.primaryIcon,
    this.primaryColor,
    required this.onPrimaryPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isPrimaryEnabled ? onPrimaryPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor ?? AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      (primaryColor ?? AppColors.primaryColor).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (primaryIcon != null) ...[
                      Icon(primaryIcon),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (primaryIcon == null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ],
                ),
              ),
            ),
            if (canGoBack) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: onBackPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    side: BorderSide(
                      color: AppColors.textColor.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 6),
                      Text('Back'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
