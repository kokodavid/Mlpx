import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import '../models/question_model.dart';
import '../providers/question_state_provider.dart';

class WordMatchingQuestion extends ConsumerWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const WordMatchingQuestion({
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
          // Title
          Text(
            question.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Word prompt — shown prominently
          if (question.correctAnswer is String) ...[
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryColor, width: 2),
                ),
                child: Text(
                  question.correctAnswer as String,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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

          const SizedBox(height: 16),

          // Option grid — single select for word matching
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = state.selectedIndices.contains(index);
              return _WordOptionCard(
                label: option.label,
                imageUrl: option.imageUrl ?? '',
                isCorrect: option.isCorrect,
                isSelected: isSelected,
                isChecked: state.hasChecked,
                onTap: () {
                  // Single select: clear previous, select new
                  if (!state.hasChecked) {
                    controller.retry();
                    controller.toggleSelection(index);
                  }
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

// ── Option Card ──────────────────────────────────────────────────────────────

class _WordOptionCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isCorrect;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;

  const _WordOptionCard({
    required this.label,
    required this.imageUrl,
    required this.isCorrect,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _resolveBorderColor();
    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Expanded(
              child: Container(
                width: 90,
                alignment: Alignment.center,
                child: imageUrl.isEmpty
                    ? const Icon(
                        Icons.image_outlined,
                        size: 26,
                        color: AppColors.textColor,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 90,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 26,
                            color: AppColors.textColor,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
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
                      ? 'You matched the correct image!'
                      : 'Try again — look at the word carefully.',
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
