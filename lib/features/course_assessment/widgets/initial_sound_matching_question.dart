import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';
import 'question_instruction_header.dart';

class InitialSoundMatchingQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const InitialSoundMatchingQuestion({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionStateProvider(questionKey));
    final controller = ref.read(questionStateProvider(questionKey).notifier);
    final imageUrl = _resolveImageUrl(question);
    final focusInstruction = question.title.trim().isNotEmpty
        ? question.title.trim()
        : 'Tap the first letter that this word START with';

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

          // Main focus card with image
          _InitialSoundFocusCard(
            imageUrl: imageUrl,
            instruction: focusInstruction,
          ),

          const SizedBox(height: 16),

          // Letter option grid
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

String _resolveImageUrl(AssessmentQuestion question) {
  // Look for image type in mainContent first.
  for (final item in question.mainContent) {
    if (item.type == 'image' && item.value.trim().isNotEmpty) {
      return item.value.trim();
    }
  }
  // Fallback: first mainContent value if it looks like a URL.
  for (final item in question.mainContent) {
    final v = item.value.trim();
    if (v.startsWith('http')) return v;
  }
  return '';
}

class _InitialSoundFocusCard extends StatelessWidget {
  final String imageUrl;
  final String instruction;

  const _InitialSoundFocusCard({
    required this.imageUrl,
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
          // Audio → letter row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _FocusAudioTile(),
                const SizedBox(width: 14),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.textColor.withValues(alpha: 0.45),
                  size: 28,
                ),
                const SizedBox(width: 14),
                const _FocusLetterPlaceholderTile(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFD4A8D4),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 140,
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    width: 140,
                    height: 140,
                    child: Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
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

class _FocusAudioTile extends StatelessWidget {
  const _FocusAudioTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.volume_up,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _FocusLetterPlaceholderTile extends StatelessWidget {
  const _FocusLetterPlaceholderTile();

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
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 2,
        color: AppColors.primaryColor.withValues(alpha: 0.5),
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
