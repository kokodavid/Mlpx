import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

enum _AssessmentFeedbackMode { section, finalResult }

/// Data for a single category score row.
class CategoryScore {
  final String label;
  final String displayLetter;
  final int correct;
  final int total;

  const CategoryScore({
    required this.label,
    required this.displayLetter,
    required this.correct,
    required this.total,
  });
}

/// Shared feedback UI used both for section breakers and final assessment result.
class AssessmentFeedback extends StatelessWidget {
  final _AssessmentFeedbackMode _mode;
  final int? sectionNumber;
  final int correctCount;
  final int totalCount;
  final List<CategoryScore> categoryScores;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  const AssessmentFeedback.section({
    super.key,
    required int section,
    required this.correctCount,
    required this.totalCount,
    required this.categoryScores,
    required VoidCallback onNext,
    required VoidCallback onReview,
    required bool isFinalSection,
  })  : _mode = _AssessmentFeedbackMode.section,
        sectionNumber = section,
        onPrimaryAction = onNext,
        primaryActionLabel = isFinalSection ? 'Finish' : 'Next',
        onSecondaryAction = onReview,
        secondaryActionLabel = 'Review';

  const AssessmentFeedback.finalResult({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.categoryScores,
    required VoidCallback onDone,
  })  : _mode = _AssessmentFeedbackMode.finalResult,
        sectionNumber = null,
        onPrimaryAction = onDone,
        primaryActionLabel = 'Done',
        onSecondaryAction = null,
        secondaryActionLabel = null;

  bool get _isSection => _mode == _AssessmentFeedbackMode.section;

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final passed = percentage >= 70;
    final badgeColor = _isSection
        ? AppColors.successColor
        : (passed ? AppColors.successColor : AppColors.errorColor);
    final badgeText = _isSection
        ? 'Section $sectionNumber Completed'
        : (passed ? 'Assessment Complete' : 'Keep Practicing');
    final headingText = _isSection
        ? 'Congratulations'
        : (passed ? 'Congratulations' : 'Almost There');
    final scoreColor = _isSection
        ? AppColors.successColor
        : (passed ? AppColors.successColor : AppColors.primaryColor);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            headingText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
          ),
          Text(
            'Overall score',
            style: TextStyle(
              fontSize: 14,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 28),
          if (categoryScores.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'Category Scores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categoryScores.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryScoreRow(category: cat),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                primaryActionLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onSecondaryAction != null && secondaryActionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSecondaryAction,
                icon: const Icon(Icons.undo, size: 18),
                label: Text(
                  secondaryActionLabel!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                      color: AppColors.borderColor, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryScoreRow extends StatelessWidget {
  final CategoryScore category;

  const _CategoryScoreRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            category.displayLetter,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${category.correct}/${category.total} Correct',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
