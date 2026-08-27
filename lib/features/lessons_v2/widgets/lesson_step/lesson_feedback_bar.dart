import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonFeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final double borderRadius;
  final String? title;
  final String? subtitle;
  final bool showActionButton;
  final bool actionOnly;
  final bool centerIconWithTitle;
  final double? actionOnlyWidth;
  final double? actionOnlyHeight;

  const LessonFeedbackBar({
    super.key,
    required this.isCorrect,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
    this.borderRadius = 20,
    this.title,
    this.subtitle,
    this.showActionButton = true,
    this.actionOnly = false,
    this.centerIconWithTitle = false,
    this.actionOnlyWidth,
    this.actionOnlyHeight,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final backgroundColor =
        isCorrect ? const Color(0xFFF2F8EE) : const Color(0xFFFFF1F0);

    final hasTitle = title != null && title!.isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final hasMessage = message.isNotEmpty;
    if (actionOnly) {
      return SizedBox(
        width: actionOnlyWidth,
        height: actionOnlyHeight,
        child: OutlinedButton.icon(
          onPressed: onActionPressed,
          icon: Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 17,
          ),
          label: Text(actionLabel),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: borderColor,
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: hasTitle
          ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: hasTitle && !centerIconWithTitle
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: borderColor,
            size: hasTitle ? 22 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasTitle
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: borderColor,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: borderColor,
                          ),
                        ),
                      ],
                      if (hasMessage) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF727272),
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: borderColor,
                    ),
                  ),
          ),
          if (showActionButton) ...[
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
        ],
      ),
    );
  }
}
