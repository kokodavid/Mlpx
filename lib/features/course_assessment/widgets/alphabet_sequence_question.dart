import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import 'question_instruction_header.dart';

class AlphabetSequenceQuestion extends ConsumerStatefulWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const AlphabetSequenceQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  ConsumerState<AlphabetSequenceQuestion> createState() =>
      _AlphabetSequenceQuestionState();
}

class _AlphabetSequenceQuestionState
    extends ConsumerState<AlphabetSequenceQuestion> {
  /// Letters placed in the answer boxes, in order.
  final List<String> _placedLetters = [];
  bool _hasChecked = false;
  bool _isCorrect = false;

  late final List<String> _allOptionLabels;
  late final List<String> _correctOrder;

  @override
  void initState() {
    super.initState();
    _allOptionLabels =
        widget.question.options.map((o) => o.label).toList(growable: false);
    _correctOrder = _resolveCorrectOrder(widget.question, _allOptionLabels);
  }

  int get _totalSlots => _allOptionLabels.length;

  /// Options still available (not yet placed).
  List<String> get _availableOptions {
    final placed = {..._placedLetters};
    final available = <String>[];
    for (final label in _allOptionLabels) {
      if (placed.contains(label)) {
        // Remove from placed set so duplicates are handled correctly.
        placed.remove(label);
      } else {
        available.add(label);
      }
    }
    return available;
  }

  void _placeOption(String letter) {
    if (_hasChecked || _placedLetters.length >= _totalSlots) return;
    setState(() {
      _placedLetters.add(letter);
    });
  }

  void _removePlacedAt(int index) {
    if (_hasChecked) return;
    setState(() {
      _placedLetters.removeAt(index);
    });
  }

  void _checkAnswer() {
    final correct = _placedLetters.length == _correctOrder.length &&
        List.generate(_correctOrder.length,
            (i) => _placedLetters[i] == _correctOrder[i]).every((v) => v);
    setState(() {
      _hasChecked = true;
      _isCorrect = correct;
    });
    widget.onAnswerChecked?.call(correct);
  }

  void _retry() {
    setState(() {
      _placedLetters.clear();
      _hasChecked = false;
      _isCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.question.title.trim().isNotEmpty
        ? widget.question.title.trim()
        : 'Taps to arrange in order';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionInstructionHeader(
            question: widget.question,
            sourceId: '${widget.questionKey}-instruction',
          ),

          const SizedBox(height: 20),

          // Focus card: example + answer slots + instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Example
                if (widget.question.example.length >= 2) ...[
                  _ExampleCard(
                    beforeLetters:
                        _parseExampleLetters(widget.question.example[0]),
                    afterLetters:
                        _parseExampleLetters(widget.question.example[1]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Answer slots (centered)
                Center(
                  child: _AnswerSlots(
                    totalSlots: _totalSlots,
                    placedLetters: _placedLetters,
                    hasChecked: _hasChecked,
                    correctOrder: _correctOrder,
                    onRemove: _removePlacedAt,
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
          _OptionsGrid(
            available: _availableOptions,
            hasChecked: _hasChecked,
            onTap: _placeOption,
          ),

          const SizedBox(height: 14),

          // Next / Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_hasChecked) {
                  _retry();
                } else if (_placedLetters.length == _totalSlots) {
                  _checkAnswer();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _placedLetters.length == _totalSlots || _hasChecked
                    ? AppColors.primaryColor
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _hasChecked
                    ? (_isCorrect ? 'Continue' : 'Retry')
                    : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Feedback
          if (_hasChecked)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _isCorrect ? _SuccessFeedback() : _ErrorFeedback(),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

List<String> _resolveCorrectOrder(
  AssessmentQuestion question,
  List<String> optionLabels,
) {
  // Try correctAnswer as a list of strings.
  final ca = question.correctAnswer;
  if (ca is List && ca.isNotEmpty) {
    return ca.map((e) => e.toString()).toList(growable: false);
  }
  // Try correctAnswer as space-separated string.
  if (ca is String && ca.trim().isNotEmpty) {
    final parts = ca.trim().split(RegExp(r'[\s,]+'));
    if (parts.length == optionLabels.length) {
      return parts;
    }
  }
  // Try second example string (the correct ordering).
  if (question.example.length >= 2) {
    final parts = _parseExampleLetters(question.example[1]);
    if (parts.length == optionLabels.length) {
      return parts;
    }
  }
  // Fallback: alphabetical sort.
  final sorted = List<String>.from(optionLabels)..sort();
  return sorted;
}

List<String> _parseExampleLetters(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const [];

  final tokens = trimmed
      .split(RegExp(r'[\s,]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (tokens.length > 1) {
    return tokens;
  }

  // Single compact token (e.g., "ABC"): render as one tile per character.
  return tokens.first.split('');
}

// ── Example Card ─────────────────────────────────────────────────────────────

class _ExampleCard extends StatelessWidget {
  final List<String> beforeLetters;
  final List<String> afterLetters;

  const _ExampleCard({
    required this.beforeLetters,
    required this.afterLetters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Example',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Before (original order)
                ...beforeLetters.map(
                  (l) => _ExampleLetterTile(letter: l, highlighted: false),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.black45,
                    size: 22,
                  ),
                ),
                // After (correct order)
                ...afterLetters.map(
                  (l) => _ExampleLetterTile(letter: l, highlighted: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleLetterTile extends StatelessWidget {
  final String letter;
  final bool highlighted;

  const _ExampleLetterTile({
    required this.letter,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: highlighted ? Colors.white : AppColors.textColor,
        ),
      ),
    );
  }
}

// ── Answer Slots ─────────────────────────────────────────────────────────────

class _AnswerSlots extends StatelessWidget {
  final int totalSlots;
  final List<String> placedLetters;
  final bool hasChecked;
  final List<String> correctOrder;
  final void Function(int index) onRemove;

  const _AnswerSlots({
    required this.totalSlots,
    required this.placedLetters,
    required this.hasChecked,
    required this.correctOrder,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalSlots, (index) {
        final isFilled = index < placedLetters.length;
        final letter = isFilled ? placedLetters[index] : null;

        Color bgColor = Colors.white;
        Color borderColor = AppColors.primaryColor.withValues(alpha: 0.4);

        if (hasChecked && isFilled) {
          final isPositionCorrect =
              index < correctOrder.length && letter == correctOrder[index];
          bgColor = isPositionCorrect
              ? AppColors.primaryColor
              : AppColors.errorColor;
          borderColor = bgColor;
        } else if (isFilled) {
          bgColor = AppColors.primaryColor;
          borderColor = AppColors.primaryColor;
        }

        return GestureDetector(
          onTap: isFilled && !hasChecked ? () => onRemove(index) : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isFilled ? bgColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1.6,
                style: isFilled ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            alignment: Alignment.center,
            child: isFilled
                ? Text(
                    letter!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 18,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// ── Options Grid ─────────────────────────────────────────────────────────────

class _OptionsGrid extends StatelessWidget {
  final List<String> available;
  final bool hasChecked;
  final void Function(String letter) onTap;

  const _OptionsGrid({
    required this.available,
    required this.hasChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: available.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final letter = available[index];
        return GestureDetector(
          onTap: hasChecked ? null : () => onTap(letter),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 2),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
          ),
        );
      },
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
