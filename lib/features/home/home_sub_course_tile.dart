import 'package:flutter/material.dart';
import 'package:milpress/shared/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';

class HomeSubCourseTile extends StatelessWidget {
  final int modulesCount;
  final int lessonsCount;
  final bool isEligible;
  final String eligibilityText;
  final String buttonText;
  final VoidCallback? onStartCourse;
  final EdgeInsetsGeometry margin;

  const HomeSubCourseTile({
    super.key,
    required this.modulesCount,
    required this.lessonsCount,
    this.isEligible = true,
    this.eligibilityText = 'You are eligible to start this level',
    this.buttonText = 'Start Course',
    this.onStartCourse,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final eligibilityColor =
        isEligible ? const Color(0xFF6AA84F) : AppColors.textColor;
    final iconBackground =
        isEligible ? const Color(0xFFDDE9D6) : const Color(0xFFE7E7E7);

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
              onPressed: (isEligible && onStartCourse != null)
                  ? onStartCourse!
                  : () {},
              isFullWidth: true,
              isPrimary: true,
              height: 48,
              backgroundColor:
                  isEligible ? AppColors.primaryColor : AppColors.textColor,
              textColor: Colors.white,
              fontSize: 16,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              fontSize: 14,
              color: Color(0xFF6C6C6C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
