import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';

class TrueFalseQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const TrueFalseQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);

    // Index 0 = True, Index 1 = False
    final correctAnswer = question.correctAnswer as bool? ?? true;
    final trueIsCorrect = correctAnswer == true;
    final selectedTrue = state.selectedIndices.contains(0);
    final selectedFalse = state.selectedIndices.contains(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            question.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Audio prompt or text prompt
          if (question.audioUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: LessonAudioInlineButton(
                sourceId: '$questionKey-instruction',
                url: question.audioUrl,
                label: question.prompt,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                question.prompt,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Statement card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              question.statement ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // True / False buttons
          Row(
            children: [
              Expanded(
                child: _TrueFalseButton(
                  label: 'True',
                  icon: Icons.check_circle_outline,
                  isSelected: selectedTrue,
                  isChecked: state.hasChecked,
                  isCorrectChoice: trueIsCorrect,
                  onTap: () {
                    if (!state.hasChecked) {
                      controller.retry();
                      controller.toggleSelection(0);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TrueFalseButton(
                  label: 'False',
                  icon: Icons.cancel_outlined,
                  isSelected: selectedFalse,
                  isChecked: state.hasChecked,
                  isCorrectChoice: !trueIsCorrect,
                  onTap: () {
                    if (!state.hasChecked) {
                      controller.retry();
                      controller.toggleSelection(1);
                    }
                  },
                ),
              ),
            ],
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
                        // Build correct flags: [trueIsCorrect, !trueIsCorrect]
                        final correctFlags = [trueIsCorrect, !trueIsCorrect];
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

// ── True / False Button ──────────────────────────────────────────────────────

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isChecked;
  final bool isCorrectChoice;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isChecked,
    required this.isCorrectChoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _resolveBorderColor();
    final bgColor = _resolveBgColor();
    final textColor = isSelected && !isChecked
        ? Colors.white
        : (isChecked && isSelected ? Colors.white : AppColors.textColor);

    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveBorderColor() {
    if (!isChecked) {
      return isSelected ? AppColors.primaryColor : AppColors.borderColor;
    }
    if (!isSelected) return AppColors.borderColor;
    return isCorrectChoice
        ? AppColors.correctAnswerColor
        : AppColors.errorColor;
  }

  Color _resolveBgColor() {
    if (!isChecked) {
      return isSelected ? AppColors.primaryColor : Colors.white;
    }
    if (!isSelected) return Colors.white;
    return isCorrectChoice ? AppColors.successColor : AppColors.errorColor;
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
                  isCorrect ? 'Correct!' : 'Not quite!',
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
                      ? 'You got it right!'
                      : 'The correct answer is ${isCorrect ? "True" : "the other option"}. Try again!',
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
