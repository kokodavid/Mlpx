

import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';




class LessonStepProgressHeader extends StatelessWidget {
  /// The current item index (1-based).
  final int current;

  /// The total number of items.
  final int total;

  /// Prefix shown before "N of M", e.g. "Word", "Question", "Activity".
  /// Defaults to "Item".
  final String itemLabel;

  /// Optional score to show on the right side ("Score: score/total").
  /// Pass null to hide the score badge.
  final int? score;

  /// Progress bar fill colour. Defaults to [AppColors.primaryColor].
  final Color barColor;

  /// Progress bar height in logical pixels. Defaults to 8.
  final double barHeight;

  /// Progress bar background colour. Defaults to `Color(0xFFF3E8DD)`.
  final Color barBackgroundColor;

  const LessonStepProgressHeader({
    super.key,
    required this.current,
    required this.total,
    this.itemLabel = 'Item',
    this.score,
    this.barColor = AppColors.primaryColor,
    this.barHeight = 8,
    this.barBackgroundColor = const Color(0xFFF3E8DD),
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$itemLabel $safeCurrent of $safeTotal',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (score != null) ...[
              const Spacer(),
              Text(
                'Score: $score/$safeTotal',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: barHeight,
            backgroundColor: barBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}



class LessonStepCard extends StatelessWidget {
  final Widget child;

  /// Card background colour. Defaults to white.
  final Color color;

  /// Card elevation (shadow depth). Defaults to 3.
  final double elevation;

  /// Corner radius. Defaults to 24.
  final double borderRadius;

  /// Inner padding. Defaults to `EdgeInsets.all(20)`.
  final EdgeInsetsGeometry padding;

  /// Optional border. Not shown when null.
  final Border? border;

  const LessonStepCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.elevation = 3,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    // When a border is specified we use a decorated Container so the border
    // is visible on top of the Card's own background.
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06 * elevation / 3),
                    blurRadius: elevation * 4,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: padding,
        child: child,
      );
    }

    return Card(
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: color,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}



class LessonFeedbackBar extends StatelessWidget {
  /// Whether the answer was correct.
  final bool isCorrect;

  /// Feedback message shown next to the icon.
  final String message;

  /// Label on the action button (e.g. "Continue", "Try Again").
  final String actionLabel;

  /// Callback when the action button is tapped.
  final VoidCallback onActionPressed;

  /// Corner radius of the container. Defaults to 18.
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
    final borderColor = isCorrect ? AppColors.successColor : AppColors.errorColor;
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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



class LessonStepInstructionSection extends StatelessWidget {
  final String stepKey;

  /// Title / instruction text to display below the audio button.
  final String title;

  /// Audio URL for the instruction. Pass empty string to show the static icon.
  final String audioUrl;

  /// Background colour of the audio button. Defaults to [AppColors.primaryColor].
  final Color audioBackgroundColor;

  /// Whether the audio button should render as a circular icon.
  final bool audioButtonIsCircular;

  /// Optional default icon for the audio button when not playing.
  final IconData? audioButtonDefaultIcon;

  /// Icon button size. Defaults to 44.
  final double buttonSize;

  const LessonStepInstructionSection({
    super.key,
    required this.stepKey,
    required this.title,
    required this.audioUrl,
    this.audioBackgroundColor = AppColors.primaryColor,
    this.audioButtonIsCircular = false,
    this.audioButtonDefaultIcon,
    this.buttonSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (audioUrl.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-instruction',
            url: audioUrl,
            backgroundColor: audioBackgroundColor,
            iconColor: Colors.white,
            isCircular: audioButtonIsCircular,
            defaultIcon: audioButtonDefaultIcon,
          )
        else
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: audioBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: buttonSize * 0.55,
            ),
          ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
            ),
          ),
        ],
      ],
    );
  }
}



class LessonStepNextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  /// Button height in logical pixels. Defaults to 52.
  final double height;

  /// Corner radius. Defaults to 16.
  final double borderRadius;

  const LessonStepNextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}



class LessonStepTipBanner extends StatelessWidget {
  final String text;

  /// Corner radius. Defaults to 14.
  final double borderRadius;

  const LessonStepTipBanner({
    super.key,
    required this.text,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFD9D0C7)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textColor,
          height: 1.3,
        ),
      ),
    );
  }
}



class LessonStepChevronDown extends StatelessWidget {
  final Color color;
  final double size;

  const LessonStepChevronDown({
    super.key,
    this.color = AppColors.textColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.keyboard_double_arrow_down_rounded,
        color: color,
        size: size,
      ),
    );
  }
}