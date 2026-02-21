import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class SelectMatchingSoundQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const SelectMatchingSoundQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);
    final mainDisplayValue = _resolveMainDisplayValue(question);
    final focusLetter = _resolveFocusLetter(question, mainDisplayValue);
    final focusInstruction = question.title.trim().isNotEmpty
        ? question.title.trim()
        : 'Tap the sound that matches with letter';

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

          // Main focus card
          if (focusLetter.isNotEmpty || mainDisplayValue.isNotEmpty)
            _MatchingSoundFocusCard(
              focusLetter: focusLetter,
              mainDisplayValue: mainDisplayValue,
              instruction: focusInstruction,
            ),

          const SizedBox(height: 16),

          // Sound options
          ...List.generate(question.options.length, (index) {
            final option = question.options[index];
            final isSelected = state.selectedIndices.contains(index);

            Color borderColor = AppColors.borderColor;
            if (state.hasChecked && isSelected) {
              borderColor = option.isCorrect
                  ? AppColors.correctAnswerColor
                  : AppColors.errorColor;
            } else if (state.hasChecked && option.isCorrect) {
              borderColor = AppColors.correctAnswerColor;
            } else if (isSelected) {
              borderColor = AppColors.primaryColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: state.hasChecked
                    ? null
                    : () {
                        // Single-select: clear previous selection, then select.
                        for (final i in state.selectedIndices.toList()) {
                          controller.toggleSelection(i);
                        }
                        controller.toggleSelection(index);
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      // Play button
                      LessonAudioInlineButton(
                        sourceId: '$questionKey-option-$index',
                        url: option.label,
                        backgroundColor:
                            AppColors.primaryColor.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 12),
                      // Waveform
                      Expanded(
                        child: SvgPicture.asset(
                          'assets/audio_wave.svg',
                          height: 24,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Radio indicator
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.textColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // Next / Retry button
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
                    : 'Next',
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
              child: state.isCorrect ? _SuccessFeedback() : _ErrorFeedback(),
            ),
        ],
      ),
    );
  }
}

String _resolveMainDisplayValue(AssessmentQuestion question) {
  if (question.mainContentValues.isNotEmpty) {
    final value = question.mainContentValues.first.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return question.targetLetter?.trim() ?? '';
}

String _resolveFocusLetter(
  AssessmentQuestion question,
  String fallbackValue,
) {
  if (question.example.isNotEmpty) {
    final value = question.example.first.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  if (question.targetLetter?.trim().isNotEmpty ?? false) {
    return question.targetLetter!.trim();
  }

  return fallbackValue;
}

class _MatchingSoundFocusCard extends StatelessWidget {
  final String focusLetter;
  final String mainDisplayValue;
  final String instruction;

  const _MatchingSoundFocusCard({
    required this.focusLetter,
    required this.mainDisplayValue,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FocusLetterTile(letter: focusLetter),
                const SizedBox(width: 14),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.textColor.withValues(alpha: 0.45),
                  size: 28,
                ),
                const SizedBox(width: 14),
                const _FocusAudioTile(),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                mainDisplayValue,
                style: const TextStyle(
                  fontSize: 140,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 0.95,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.keyboard_double_arrow_down,
            size: 32,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 8),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusLetterTile extends StatelessWidget {
  final String letter;

  const _FocusLetterTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

class _FocusAudioTile extends StatelessWidget {
  const _FocusAudioTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.7),
          width: 1.4,
        ),
      ),
      child: Icon(
        Icons.volume_up,
        color: AppColors.primaryColor.withValues(alpha: 0.95),
        size: 20,
      ),
    );
  }
}

// ── Feedback Widgets ─────────────────────────────────────────────────────────

class _SuccessFeedback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          top: BorderSide(color: AppColors.successColor, width: 1),
          bottom: BorderSide(color: AppColors.successColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF66BB6A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excellent work!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You got the right answer!',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorFeedback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.accentColor,
        border: Border(
          top: BorderSide(color: AppColors.errorColor, width: 1),
          bottom: BorderSide(color: AppColors.errorColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.errorColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review the correct answers and try again.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
