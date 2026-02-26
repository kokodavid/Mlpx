import 'package:flutter/material.dart';
import 'package:milpress/features/home_v2/providers/home_v2_provider.dart';
import 'package:milpress/features/home_v2/widgets/audio_preview_widget.dart';


// CourseCardWidget

class CourseCardWidget extends StatelessWidget {
  final CourseCardViewModel viewModel;

  const CourseCardWidget({
    super.key,
    required this.viewModel,
  });

  String get _courseLabel =>
      'Course ${viewModel.courseWithDetails.course.level}';

  String get _categoryLabel {
    final type = viewModel.courseWithDetails.course.type;
    if (type == null || type.trim().isEmpty) return 'BEGINNER';
    return type.trim().toUpperCase();
  }

  bool get _isCompleted => false; // completion handled outside the card

  @override
  Widget build(BuildContext context) {
    final course = viewModel.courseWithDetails.course;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // layer 0: deepest decorative card
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          //  layer 1: middle decorative card
          Positioned(
            top: 8,
            left: 9,
            right: 9,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // layer 2: main card
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

                  // badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OutlinedBadge(
                        label: _courseLabel,
                        borderColor: const Color(0xFFE8844A),
                        textColor: const Color(0xFFE8844A),
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(width: 10),
                      _OutlinedBadge(
                        label: _categoryLabel,
                        borderColor: const Color(0xFFD1D5DB),
                        textColor: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // audio preview
                  AudioPreviewWidget(
                    soundUrl: course.soundUrlPreview,
                    sourceId: course.id,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OutlinedBadge
// ---------------------------------------------------------------------------
class _OutlinedBadge extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  const _OutlinedBadge({
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