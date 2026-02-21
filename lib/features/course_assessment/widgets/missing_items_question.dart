import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class MissingItemsQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const MissingItemsQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);

    final sequenceTokens = _parseSequence(question);
    final exampleLetters = _parseExample(question);
    final exampleHighlightIndex =
        _resolveExampleHighlightIndex(sequenceTokens, exampleLetters.length);
    final instruction = question.title.trim().isNotEmpty
        ? question.title.trim()
        : 'Selects missing letter';

    // Resolve selected letter label for the blank slot.
    String? selectedLabel;
    if (state.selectedIndices.isNotEmpty) {
      final idx = state.selectedIndices.first;
      if (idx >= 0 && idx < question.options.length) {
        selectedLabel = question.options[idx].label;
      }
    }

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

          // Focus card: example + sequence + instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Example row
                // if (exampleLetters.isNotEmpty) ...[
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 16, vertical: 12),
                //     decoration: BoxDecoration(
                //       color: const Color(0xFFF1F1F1),
                //       borderRadius: BorderRadius.circular(16),
                //     ),
                //     child: Column(
                //       children: [
                //         const Text(
                //           'Example',
                //           style: TextStyle(
                //             fontSize: 13,
                //             fontWeight: FontWeight.w500,
                //             color: Colors.black54,
                //           ),
                //         ),
                //         const SizedBox(height: 10),
                //         SingleChildScrollView(
                //           scrollDirection: Axis.horizontal,
                //           child: Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: List.generate(
                //               exampleLetters.length,
                //               (i) {
                //                 if (i == exampleHighlightIndex) {
                //                   return _ExampleDashedTile(
                //                       letter: exampleLetters[i]);
                //                 }
                //                 return _ExampleLetterTile(
                //                     letter: exampleLetters[i]);
                //               },
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                //   const SizedBox(height: 16),
                // ],

                // Sequence row with blank
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sequenceTokens.map((token) {
                      if (token == '_') {
                        return _BlankSlotTile(
                          selectedLabel: selectedLabel,
                          hasChecked: state.hasChecked,
                          isCorrect: state.isCorrect,
                        );
                      }
                      return _LetterTile(letter: token, filled: true);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),
                const Icon(
                  Icons.keyboard_double_arrow_down,
                  size: 32,
                  color: AppColors.textColor,
                ),
                const SizedBox(height: 6),
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
          ),

          const SizedBox(height: 16),

          // Options grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = state.selectedIndices.contains(index);

              Color bgColor = Colors.white;
              Color borderColor = AppColors.borderColor;
              Color textColor = AppColors.textColor;

              if (state.hasChecked && isSelected) {
                if (option.isCorrect) {
                  bgColor = AppColors.correctAnswerColor;
                  borderColor = AppColors.correctAnswerColor;
                  textColor = Colors.white;
                } else {
                  bgColor = AppColors.errorColor;
                  borderColor = AppColors.errorColor;
                  textColor = Colors.white;
                }
              } else if (state.hasChecked && option.isCorrect) {
                borderColor = AppColors.correctAnswerColor;
              } else if (isSelected) {
                borderColor = AppColors.primaryColor;
              }

              return GestureDetector(
                onTap: state.hasChecked
                    ? null
                    : () {
                        // Single-select: clear previous, then select.
                        for (final i in state.selectedIndices.toList()) {
                          controller.toggleSelection(i);
                        }
                        controller.toggleSelection(index);
                      },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),

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

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Parse main content value like "DEFG_I" into tokens: ["D","E","F","G","_","I"].
List<String> _parseSequence(AssessmentQuestion question) {
  for (final item in question.mainContent) {
    final v = item.value.trim();
    if (v.isNotEmpty) {
      return v.split('');
    }
  }
  return const [];
}

/// Parse example string like "ABCD" into individual letters.
List<String> _parseExample(AssessmentQuestion question) {
  if (question.example.isEmpty) return const [];
  final raw = question.example.first.trim();
  if (raw.isEmpty) return const [];

  // If space-separated, split by spaces; otherwise split per character.
  final spaced = raw.split(RegExp(r'[\s,]+'));
  if (spaced.length > 1) return spaced;
  return raw.split('');
}

/// Find which example index to highlight with a dashed border,
/// based on the proportional position of '_' in the main content sequence.
int _resolveExampleHighlightIndex(
    List<String> sequenceTokens, int exampleLength) {
  if (exampleLength == 0) return -1;
  final blankIndex = sequenceTokens.indexOf('_');
  if (blankIndex < 0) return exampleLength ~/ 2;
  // Proportional mapping: blankIndex / sequenceLength → exampleIndex / exampleLength
  final ratio = blankIndex / sequenceTokens.length;
  return (ratio * exampleLength).floor().clamp(0, exampleLength - 1);
}

// ── Tiles ────────────────────────────────────────────────────────────────────

class _LetterTile extends StatelessWidget {
  final String letter;
  final bool filled;

  const _LetterTile({required this.letter, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : AppColors.textColor,
        ),
      ),
    );
  }
}

class _ExampleLetterTile extends StatelessWidget {
  final String letter;

  const _ExampleLetterTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _ExampleDashedTile extends StatelessWidget {
  final String letter;

  const _ExampleDashedTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.6),
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _BlankSlotTile extends StatelessWidget {
  final String? selectedLabel;
  final bool hasChecked;
  final bool isCorrect;

  const _BlankSlotTile({
    required this.selectedLabel,
    required this.hasChecked,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = selectedLabel != null;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.primaryColor.withValues(alpha: 0.5);
    Color textColor = Colors.white;

    if (hasChecked && isFilled) {
      if (isCorrect) {
        bgColor = AppColors.correctAnswerColor.withValues(alpha: 0.15);
        borderColor = AppColors.correctAnswerColor;
        textColor = AppColors.correctAnswerColor;
      } else {
        bgColor = Colors.white;
        borderColor = AppColors.errorColor;
        textColor = AppColors.errorColor;
      }
    } else if (isFilled) {
      bgColor = AppColors.primaryColor.withValues(alpha: 0.15);
      borderColor = AppColors.primaryColor;
      textColor = AppColors.primaryColor;
    }

    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: isFilled
          ? Text(
              selectedLabel!,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            )
          : Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
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
