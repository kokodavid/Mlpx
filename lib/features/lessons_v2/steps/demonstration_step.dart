import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/tracing_canvas.dart';

class DemonstrationStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const DemonstrationStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<DemonstrationStep> createState() => _DemonstrationStepState();
}

class _DemonstrationStepState extends State<DemonstrationStep> {
  int _selectedIndex = 0;
  final TracingCanvasController _tracingController =
  TracingCanvasController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Demonstration';
    final feedbackTitle =
        widget.step.config['feedbackTitle'] as String? ?? 'Nice work!';
    final feedbackBody = widget.step.config['feedbackBody'] as String? ??
        'You are forming the letter well.';
    final imageUrls =
    (widget.step.config['image_urls'] as List<dynamic>? ?? [])
        .map((url) => url.toString())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < imageUrls.length; i++) ...[
                SizedBox(
                  width: 140,
                  child: _SvgTab(
                    url: imageUrls[i],
                    isActive: i == _selectedIndex,
                    onTap: () {
                      setState(() {
                        _selectedIndex = i;
                      });
                    },
                  ),
                ),
                if (i != imageUrls.length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: TracingCanvas(controller: _tracingController),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _tracingController.clear,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.copBlue,
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: AppColors.correctAnswerColor.withOpacity(0.12),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: AppColors.correctAnswerColor.withOpacity(0.3),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 36,
          //         height: 36,
          //         decoration: const BoxDecoration(
          //           color: AppColors.correctAnswerColor,
          //           shape: BoxShape.circle,
          //         ),
          //         child: const Icon(Icons.check, color: Colors.white),
          //       ),
          //       const SizedBox(width: 10),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               feedbackTitle,
          //               style: const TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: FontWeight.w600,
          //                 color: AppColors.correctAnswerColor,
          //               ),
          //             ),
          //             Text(
          //               feedbackBody,
          //               style: TextStyle(
          //                 fontSize: 12,
          //                 color: AppColors.correctAnswerColor.withOpacity(0.9),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _SvgTab extends StatelessWidget {
  final String url;
  final bool isActive;
  final VoidCallback onTap;

  const _SvgTab({
    required this.url,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: isActive
              ? Border.all(
            color: AppColors.primaryColor,
            width: 2.5,
          )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), // 👈 SAME radius
          clipBehavior: Clip.antiAlias,
          child: SvgPicture.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            colorFilter: isActive
                ? null
                : const ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
