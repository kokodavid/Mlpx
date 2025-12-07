import 'package:flutter/material.dart';

class ProgressWidget extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final BorderRadius? borderRadius;

  const ProgressWidget({
    super.key,
    required this.progress,
    this.label,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surfaceVariant;
    final effectiveProgressColor = progressColor ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: effectiveBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveProgressColor),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}
