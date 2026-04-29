import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

enum OptionButtonVariant { letterTile, answerChip }

enum OptionButtonState { idle, selected, correct, incorrect }

class OptionButton extends StatelessWidget {
  final String label;
  final OptionButtonVariant variant;
  final OptionButtonState state;
  final bool locked;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.label,
    required this.variant,
    required this.state,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      OptionButtonVariant.letterTile => _buildLetterTile(),
      OptionButtonVariant.answerChip => _buildAnswerChip(),
    };
  }

  Widget _buildLetterTile() {
    final isSelected = state == OptionButtonState.selected;

    final Color bgColor =
        isSelected ? const Color(0xFFFAEDE6) : Colors.white;

    final BoxBorder border = isSelected
        ? Border(
            top: BorderSide(color: AppColors.primaryColor, width: 4.0),
            bottom: BorderSide(color: AppColors.primaryColor, width: 4.0),
            left: BorderSide(color: AppColors.primaryColor, width: 1.5),
            right: BorderSide(color: AppColors.primaryColor, width: 1.5),
          )
        : Border.all(color: const Color(0xFFE0DBD5), width: 1.5);

    final Color textColor =
        isSelected ? AppColors.primaryColor : const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: border,
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerChip() {
    final Color bgColor = switch (state) {
      OptionButtonState.idle => Colors.white,
      OptionButtonState.selected => Colors.white,
      OptionButtonState.correct => AppColors.successColor.withOpacity(0.06),
      OptionButtonState.incorrect => AppColors.errorColor.withOpacity(0.06),
    };

    final Color borderAccent = switch (state) {
      OptionButtonState.idle => const Color(0xFFD9D5CF),
      OptionButtonState.selected => AppColors.primaryColor,
      OptionButtonState.correct => AppColors.successColor,
      OptionButtonState.incorrect => AppColors.errorColor,
    };

    final bool useThickBorder = state == OptionButtonState.selected ||
        state == OptionButtonState.correct ||
        state == OptionButtonState.incorrect;

    final BoxBorder border = useThickBorder
        ? Border(
            top: BorderSide(color: borderAccent, width: 3.5),
            bottom: BorderSide(color: borderAccent, width: 3.5),
            left: BorderSide(color: borderAccent, width: 2.0),
            right: BorderSide(color: borderAccent, width: 2.0),
          )
        : Border.all(color: borderAccent, width: 1.5);

    final Color textColor = switch (state) {
      OptionButtonState.idle => const Color(0xFF9E9E9E),
      OptionButtonState.selected => AppColors.primaryColor,
      OptionButtonState.correct => AppColors.successColor,
      OptionButtonState.incorrect => AppColors.errorColor,
    };

    return GestureDetector(
      onTap: (locked || state != OptionButtonState.idle) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: border,
          boxShadow: state == OptionButtonState.idle
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
