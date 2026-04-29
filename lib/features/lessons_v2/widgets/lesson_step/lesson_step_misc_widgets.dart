import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonStepNextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;
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

class LessonStepTitle extends StatelessWidget {
  final String title;

  const LessonStepTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF171B22),
      ),
    );
  }
}
