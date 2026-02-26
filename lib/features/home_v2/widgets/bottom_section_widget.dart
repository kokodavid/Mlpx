import 'package:flutter/material.dart';
import 'package:milpress/features/home_v2/providers/home_v2_provider.dart';
import 'package:milpress/features/home_v2/widgets/pill_badge_widget.dart';
import 'package:milpress/shared/widgets/custom_button.dart';


// BottomSectionWidget

class BottomSectionWidget extends StatelessWidget {
  final CourseCardViewModel viewModel;
  final VoidCallback? onCtaTap;
  final CourseCardState? overrideState;

  const BottomSectionWidget({
    super.key,
    required this.viewModel,
    this.onCtaTap,
    this.overrideState,
  });

  CourseCardState get _state => overrideState ?? viewModel.state;

  //  CTA label
  String get _ctaLabel {
    switch (_state) {
      case CourseCardState.startCourse:    return 'Start Course';
      case CourseCardState.continueCourse: return 'Continue';
      case CourseCardState.comingNext:     return 'Coming Next';
      case CourseCardState.reviewCourse:   return 'Review Course';
    }
  }

  //  CTA colour
  Color get _ctaColor {
    switch (_state) {
      case CourseCardState.startCourse:
      case CourseCardState.continueCourse: return const Color(0xFFE8844A);
      case CourseCardState.comingNext:     return const Color(0xFF9CA3AF);
      case CourseCardState.reviewCourse:   return const Color(0xFF22C55E);
    }
  }

  bool get _ctaEnabled => _state != CourseCardState.comingNext;

  // Eligibility text
  String get _eligibilityLabel {
    switch (_state) {
      case CourseCardState.startCourse:    return 'You are eligible to start this level';
      case CourseCardState.continueCourse: return 'You are eligible to continue here';
      case CourseCardState.comingNext:     return 'Finish the previous level to unlock this';
      case CourseCardState.reviewCourse:   return 'All modules completed';
    }
  }

  Color get _eligibilityDotColor {
    switch (_state) {
      case CourseCardState.startCourse:
      case CourseCardState.continueCourse:
      case CourseCardState.reviewCourse: return const Color(0xFF22C55E);
      case CourseCardState.comingNext:   return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = viewModel.courseWithDetails;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  module / lesson pills
            Row(
              children: [
                PillBadgeWidget(
                  imagePath: 'assets/modules_icon.png',
                  label: '${c.totalModules} Modules',
                ),
                const SizedBox(width: 10),
                PillBadgeWidget(
                  imagePath: 'assets/lessons_icon.png',
                  label: '${c.totalLessons} Lessons',
                ),
              ],
            ),
            const SizedBox(height: 12),

            //  eligibility row
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _eligibilityDotColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  _eligibilityLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            //  CTA button(s)
            if (_state == CourseCardState.reviewCourse)
              _ReviewCourseButtons(ctaLabel: _ctaLabel, ctaColor: _ctaColor, onCtaTap: onCtaTap)
            else
              CustomButton(
                onPressed: _ctaEnabled ? (onCtaTap ?? () {}) : () {},
                text: _ctaLabel,
                isFullWidth: true,
                height: 56,
                backgroundColor: _ctaEnabled ? _ctaColor : _ctaColor.withOpacity(0.55),
                textColor: Colors.white,
                fontSize: 17,
                borderRadius: BorderRadius.circular(20),
              ),
          ],
        ),
      ),
    );
  }
}


// _ReviewCourseButtons — inline private helper used only in BottomSectionWidget
// "Review Course" green button + replay icon button side by side.

class _ReviewCourseButtons extends StatelessWidget {
  final String ctaLabel;
  final Color ctaColor;
  final VoidCallback? onCtaTap;

  const _ReviewCourseButtons({
    required this.ctaLabel,
    required this.ctaColor,
    required this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            onPressed: onCtaTap ?? () {},
            text: ctaLabel,
            isFullWidth: true,
            height: 56,
            backgroundColor: ctaColor,
            textColor: Colors.white,
            fontSize: 17,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
          ),
          child: const Icon(
            Icons.replay_rounded,
            color: Color(0xFF6B7280),
            size: 22,
          ),
        ),
      ],
    );
  }
}