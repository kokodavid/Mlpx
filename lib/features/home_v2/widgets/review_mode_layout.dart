import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/home_v2/providers/home_v2_provider.dart';
import 'package:milpress/features/home_v2/widgets/bottom_section_widget.dart';

// ReviewModeLayout
// Full-screen layout shown when the user taps "Review Course".
// Renders a stacked card with a dark centered audio/play UI, plus the full
// BottomSectionWidget forced into the startCourse state.

class ReviewModeLayout extends StatelessWidget {
  final CourseCardViewModel viewModel;
  final VoidCallback onExit;

  const ReviewModeLayout({
    super.key,
    required this.viewModel,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final course = viewModel.courseWithDetails.course;
    final courseLabel = 'Course ${course.level}';
    final categoryLabel = (course.type == null || course.type!.trim().isEmpty)
        ? 'BEGINNER'
        : course.type!.trim().toUpperCase();

    return Column(
      children: [
        //  stacked card with dark audio UI
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Decorative layer 0 (deepest)
                Positioned(
                  top: 16, left: 18, right: 18,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Decorative layer 1 (middle)
                Positioned(
                  top: 8, left: 9, right: 9,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Main card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CourseBadge(
                              label: courseLabel,
                              borderColor: const Color(0xFFE8844A),
                              textColor: const Color(0xFFE8844A),
                              icon: Icons.school_rounded,
                            ),
                            const SizedBox(width: 10),
                            _CourseBadge(
                              label: categoryLabel,
                              borderColor: const Color(0xFFD1D5DB),
                              textColor: const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Dark play button
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F2937),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap to listen',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Course Preview',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        //  bottom section forced to startCourse state
        BottomSectionWidget(
          viewModel: viewModel,
          overrideState: CourseCardState.startCourse,
          onCtaTap: () => context.push('/course/${course.id}'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// _CourseBadge — outlined badge used only inside ReviewModeLayout

class _CourseBadge extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  const _CourseBadge({
    required this.label,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}