import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import '../models/question_model.dart';

class MatchingOptions extends ConsumerStatefulWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const MatchingOptions({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  ConsumerState<MatchingOptions> createState() => _MatchingOptionsState();
}

class _MatchingOptionsState extends ConsumerState<MatchingOptions> {
  int? _selectedIndex;
  bool _hasChecked = false;
  bool _isCorrect = false;

  int get _correctIndex =>
      widget.question.options.indexWhere((o) => o.isCorrect);

  void _onOptionTapped(int index) {
    if (_hasChecked) return;
    final isCorrect = widget.question.options[index].isCorrect;
    setState(() {
      _selectedIndex = index;
      _hasChecked = true;
      _isCorrect = isCorrect;
    });
    widget.onAnswerChecked?.call(isCorrect);

    // Allow retry on wrong answers while preserving immediate feedback.
    if (!isCorrect) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || !_hasChecked || _isCorrect) {
          return;
        }
        setState(() {
          _selectedIndex = null;
          _hasChecked = false;
          _isCorrect = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final targetContent = _resolveTargetContent(q);
    final instructionText = _resolveInstructionText(q);
    final hasFocusContent = q.example.length >= 2 ||
        targetContent.isNotEmpty ||
        instructionText.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // Audio button
          LessonAudioInlineButton(
            sourceId: '${widget.questionKey}-instruction',
            url: q.audioUrl,
            label: 'Click here to listen',
          ),
          const SizedBox(height: 18),

          // Unified focus section: example + target letter + instruction
          if (hasFocusContent) ...[
            _MatchFocusCard(question: q),
            const SizedBox(height: 14),
          ],

          // Options grid — 3-column single-select
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: q.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final option = q.options[index];
              return _OptionTile(
                label: option.label,
                isCorrect: option.isCorrect,
                isSelected: _selectedIndex == index,
                showCorrect:
                    _hasChecked && !_isCorrect && index == _correctIndex,
                isChecked: _hasChecked,
                onTap: () => _onOptionTapped(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _resolveTargetContent(AssessmentQuestion question) {
  if (question.mainContentValues.isNotEmpty) {
    final value = question.mainContentValues.first.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return question.targetLetter?.trim() ?? '';
}

String _resolveInstructionText(AssessmentQuestion question) {
  final hint = question.hintText?.trim();
  if (hint != null && hint.isNotEmpty) {
    return hint;
  }
  return question.statement?.trim() ?? '';
}

// ── Focus Card ───────────────────────────────────────────────────────────────

class _MatchFocusCard extends StatelessWidget {
  final AssessmentQuestion question;

  const _MatchFocusCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final hasExample = question.example.length >= 2;
    final targetContent = _resolveTargetContent(question);
    final hasTargetLetter = targetContent.isNotEmpty;
    final instructionText = _resolveInstructionText(question);
    final hasInstruction = instructionText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (hasExample) ...[
            _ExampleSection(items: question.example),
            if (hasTargetLetter || hasInstruction) const SizedBox(height: 22),
          ],
          if (hasTargetLetter) ...[
            Text(
              targetContent,
              style: const TextStyle(
                fontSize: 168,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 0.95,
              ),
            ),
            if (hasInstruction) const SizedBox(height: 10),
          ],
          if (hasInstruction) ...[
            const Icon(
              Icons.keyboard_double_arrow_down,
              size: 30,
              color: AppColors.textColor,
            ),
            const SizedBox(height: 10),
            Text(
              instructionText,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Example Section ──────────────────────────────────────────────────────────

class _ExampleSection extends StatelessWidget {
  final List<String> items;

  const _ExampleSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _ExampleLetterTile(
                letter: items[i],
                isPrimary: i == 0,
              ),
              if (i < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.link,
                    size: 20,
                    color: AppColors.textColor,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleLetterTile extends StatelessWidget {
  final String letter;
  final bool isPrimary;

  const _ExampleLetterTile({
    required this.letter,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isPrimary ? Colors.white : AppColors.primaryColor,
        ),
      ),
    );
  }
}

// ── Option Tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isCorrect;
  final bool isSelected;
  final bool showCorrect; // Reveal correct answer after wrong pick
  final bool isChecked;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
    required this.showCorrect,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    double borderWidth;

    if (isSelected && isChecked) {
      // Selected + checked
      bgColor = isCorrect ? AppColors.successColor : AppColors.errorColor;
      borderColor =
          isCorrect ? AppColors.successShadowColor : AppColors.errorShadowColor;
      textColor = Colors.white;
      borderWidth = 3.0;
    } else if (showCorrect) {
      // Reveal the correct answer after wrong pick
      bgColor = AppColors.successColor.withValues(alpha: 0.15);
      borderColor = AppColors.successShadowColor;
      textColor = AppColors.successShadowColor;
      borderWidth = 3.0;
    } else {
      // Default / unselected
      bgColor = Colors.white;
      borderColor = AppColors.borderColor;
      textColor = Colors.black87;
      borderWidth = 1.5;
    }

    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
