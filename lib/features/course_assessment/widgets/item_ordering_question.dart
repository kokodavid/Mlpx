import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class ItemOrderingQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const ItemOrderingQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);

    final isAfter = _resolveOrder(question) == 'after';
    final knownLetter = _resolveKnownLetter(question);
    final exampleLetters = _parseExample(question);
    final exampleLabel = _resolveExampleLabel(question, isAfter, exampleLetters);
    final instruction = question.title.trim().isNotEmpty
        ? question.title.trim()
        : isAfter
            ? 'Select the letter that comes next'
            : 'Select the letter that comes before';

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

          // Focus card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Example
                if (exampleLetters.length >= 2)
                  _ExampleRow(
                    label: exampleLabel,
                    letters: exampleLetters,
                    highlightIndex: isAfter
                        ? exampleLetters.length - 1
                        : 0,
                  ),

                const SizedBox(height: 18),

                // Main letter pair
                _LetterPair(
                  knownLetter: knownLetter,
                  selectedLabel: selectedLabel,
                  isAfter: isAfter,
                  hasChecked: state.hasChecked,
                  isCorrect: state.isCorrect,
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

String _resolveOrder(AssessmentQuestion question) {
  final order = question.extraFields['order'];
  if (order is String && order.trim().isNotEmpty) {
    return order.trim().toLowerCase();
  }
  return 'after';
}

String _resolveKnownLetter(AssessmentQuestion question) {
  // Try main content first.
  for (final item in question.mainContent) {
    final v = item.value.trim();
    if (v.isNotEmpty) return v;
  }
  // Fallback to targetLetter.
  return question.targetLetter?.trim() ?? '';
}

List<String> _parseExample(AssessmentQuestion question) {
  if (question.example.isEmpty) return const [];

  // If there are 2+ example entries, treat each as a letter.
  if (question.example.length >= 2) {
    return question.example
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  // Single entry: split by space or character.
  final raw = question.example.first.trim();
  if (raw.isEmpty) return const [];
  final spaced = raw.split(RegExp(r'[\s,]+'));
  if (spaced.length > 1) return spaced;
  return raw.split('');
}

String _resolveExampleLabel(
  AssessmentQuestion question,
  bool isAfter,
  List<String> exampleLetters,
) {
  if (exampleLetters.length >= 2) {
    final ref = isAfter ? exampleLetters.first : exampleLetters.last;
    return isAfter ? 'Example: Letter after $ref' : 'Example: Letter before $ref';
  }
  return isAfter ? 'Example' : 'Example';
}

// ── Example Row ──────────────────────────────────────────────────────────────

class _ExampleRow extends StatelessWidget {
  final String label;
  final List<String> letters;
  final int highlightIndex;

  const _ExampleRow({
    required this.label,
    required this.letters,
    required this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(letters.length, (i) {
              final isHighlighted = i == highlightIndex;
              return Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: isHighlighted
                      ? Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.6),
                          width: 1.6,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  letters[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isHighlighted
                        ? AppColors.primaryColor.withValues(alpha: 0.7)
                        : AppColors.primaryColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Letter Pair ──────────────────────────────────────────────────────────────

class _LetterPair extends StatelessWidget {
  final String knownLetter;
  final String? selectedLabel;
  final bool isAfter;
  final bool hasChecked;
  final bool isCorrect;

  const _LetterPair({
    required this.knownLetter,
    required this.selectedLabel,
    required this.isAfter,
    required this.hasChecked,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final knownTile = _LargeLetterTile(letter: knownLetter);
    final blankTile = _LargeBlankTile(
      selectedLabel: selectedLabel,
      hasChecked: hasChecked,
      isCorrect: isCorrect,
    );

    final arrow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        isAfter ? Icons.arrow_forward : Icons.arrow_back,
        color: AppColors.textColor.withValues(alpha: 0.4),
        size: 24,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isAfter
          ? [knownTile, arrow, blankTile]
          : [blankTile, arrow, knownTile],
    );
  }
}

class _LargeLetterTile extends StatelessWidget {
  final String letter;

  const _LargeLetterTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LargeBlankTile extends StatelessWidget {
  final String? selectedLabel;
  final bool hasChecked;
  final bool isCorrect;

  const _LargeBlankTile({
    required this.selectedLabel,
    required this.hasChecked,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = selectedLabel != null;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.primaryColor.withValues(alpha: 0.5);

    if (hasChecked && isFilled) {
      bgColor = isCorrect ? AppColors.correctAnswerColor : AppColors.errorColor;
      borderColor = bgColor;
    } else if (isFilled) {
      bgColor = AppColors.primaryColor.withValues(alpha: 0.15);
      borderColor = AppColors.primaryColor;
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isFilled ? bgColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isFilled
          ? Text(
              selectedLabel!,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: hasChecked ? Colors.white : AppColors.primaryColor,
              ),
            )
          : Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
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
