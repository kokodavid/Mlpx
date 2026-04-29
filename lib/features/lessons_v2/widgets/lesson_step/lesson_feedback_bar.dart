import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonFeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final double borderRadius;

  const LessonFeedbackBar({
    super.key,
    required this.isCorrect,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final backgroundColor =
        isCorrect ? const Color(0xFFF2F8EE) : const Color(0xFFFFF1F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: borderColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: borderColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
