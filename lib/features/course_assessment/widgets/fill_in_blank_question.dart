import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class FillInBlankQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const FillInBlankQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);

    // Build the sentence display with blank highlighted
    final sentence = question.sentence ?? '___';
    final selectedLabel = state.selectedIndices.isNotEmpty
        ? question.options[state.selectedIndices.first].label
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionInstructionHeader(
            question: question,
            sourceId: '$questionKey-instruction',
          ),
          const SizedBox(height: 20),

          // Sentence with blank
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: _SentenceWithBlank(
              sentence: sentence,
              filledWord: selectedLabel,
              isChecked: state.hasChecked,
              isCorrect: state.isCorrect,
            ),
          ),

          const SizedBox(height: 24),

          // Option chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(question.options.length, (index) {
              final option = question.options[index];
              final isSelected = state.selectedIndices.contains(index);
              return _OptionChip(
                label: option.label,
                isCorrect: option.isCorrect,
                isSelected: isSelected,
                isChecked: state.hasChecked,
                onTap: () {
                  if (!state.hasChecked) {
                    // Single select: clear previous, select new
                    controller.retry();
                    controller.toggleSelection(index);
                  }
                },
              );
            }),
          ),

          const SizedBox(height: 20),

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
                    : 'Check Answer',
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

// ── Sentence with Blank ──────────────────────────────────────────────────────

class _SentenceWithBlank extends StatelessWidget {
  final String sentence;
  final String? filledWord;
  final bool isChecked;
  final bool isCorrect;

  const _SentenceWithBlank({
    required this.sentence,
    this.filledWord,
    required this.isChecked,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // Split sentence on "___" or "_" patterns
    final parts = sentence.split(RegExp(r'_+'));

    final blankColor = isChecked
        ? (isCorrect ? AppColors.successColor : AppColors.errorColor)
        : AppColors.primaryColor;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.6),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: blankColor, width: 2),
                    ),
                  ),
                  child: Text(
                    filledWord ?? '          ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: blankColor,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Option Chip ──────────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isCorrect;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _resolveBorderColor();
    final bgColor = isSelected && !isChecked
        ? AppColors.primaryColor
        : (isChecked && isSelected
            ? (isCorrect ? AppColors.successColor : AppColors.errorColor)
            : Colors.white);
    final textColor = (isSelected || (isChecked && isSelected))
        ? Colors.white
        : AppColors.textColor;

    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Color _resolveBorderColor() {
    if (!isChecked) {
      return isSelected ? AppColors.primaryColor : AppColors.borderColor;
    }
    if (!isSelected) return AppColors.borderColor;
    return isCorrect ? AppColors.correctAnswerColor : AppColors.errorColor;
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
                      ? 'You filled in the correct word!'
                      : 'Try again — read the sentence carefully.',
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
