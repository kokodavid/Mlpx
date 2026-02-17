import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class LetterRecognitionQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const LetterRecognitionQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionInstructionHeader(
            question: question,
            sourceId: '$questionKey-instruction',
            audioLabel: 'Click to hear instructions',
          ),

          // // Target letter display
          // if (question.targetLetter != null) ...[
          //   Center(
          //     child: Container(
          //       width: 100,
          //       height: 100,
          //       decoration: BoxDecoration(
          //         color: AppColors.primaryColor,
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Center(
          //         child: Text(
          //           question.targetLetter!,
          //           style: const TextStyle(
          //             fontSize: 48,
          //             fontWeight: FontWeight.bold,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          // ],

          const SizedBox(height: 16),

          // Option grid — 2-column text-only letter tiles
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = state.selectedIndices.contains(index);
              return _LetterTile(
                label: option.label,
                isCorrect: option.isCorrect,
                isSelected: isSelected,
                isChecked: state.hasChecked,
                onTap: () {
                  // Enforce single-select behavior for letter recognition.
                  if (isSelected) {
                    controller.toggleSelection(index);
                    return;
                  }
                  for (final i in state.selectedIndices.toList()) {
                    controller.toggleSelection(i);
                  }
                  controller.toggleSelection(index);
                },
              );
            },
          ),

          const SizedBox(height: 14),

          // Check / Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.selectedIndices.isEmpty && !state.hasChecked
                  ? null
                  : () {
                      if (state.hasChecked) {
                        controller.retry();
                      } else {
                        final correctFlags =
                            question.options.map((o) => o.isCorrect).toList();
                        final result = controller.checkAnswers(correctFlags);
                        onAnswerChecked?.call(result);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.hasChecked
                    ? (state.isCorrect ? 'Continue' : 'Retry')
                    : 'Check Answers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Feedback
          if (state.hasChecked)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _FeedbackBanner(isCorrect: state.isCorrect),
            ),
        ],
      ),
    );
  }
}

// ── Letter Tile ──────────────────────────────────────────────────────────────

class _LetterTile extends StatelessWidget {
  final String label;
  final bool isCorrect;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;

  const _LetterTile({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _resolveBgColor();
    final borderColor = _resolveBorderColor();
    final borderWidth = isSelected ? 5.0 : 2.0;
    final textColor = isSelected
        ? Colors.white
        : (isChecked && !isSelected ? Colors.grey : Colors.black);

    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Color _resolveBgColor() {
    if (!isSelected) {
      return isChecked ? Colors.grey[200]! : Colors.white;
    }
    if (!isChecked) return AppColors.primaryColor;
    return isCorrect ? AppColors.successColor : AppColors.errorColor;
  }

  Color _resolveBorderColor() {
    if (!isSelected) return AppColors.borderColor;
    if (!isChecked) return AppColors.primaryColor;
    return isCorrect
        ? AppColors.successShadowColor
        : AppColors.errorShadowColor;
  }
}

// ── Feedback Banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;

  const _FeedbackBanner({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.backgroundColor : AppColors.accentColor,
        border: Border(
          top: BorderSide(
            color: isCorrect ? AppColors.successColor : AppColors.errorColor,
            width: 1,
          ),
          bottom: BorderSide(
            color: isCorrect ? AppColors.successColor : AppColors.errorColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF66BB6A)
                  : AppColors.errorColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.face,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Excellent work!' : 'Keep going!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCorrect
                        ? const Color(0xFF2E7D32)
                        : AppColors.errorColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCorrect
                      ? 'You got the right answer!'
                      : 'Review the correct answers and try again.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCorrect
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
