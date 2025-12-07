import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/assessment/providers/assessment_result_provider.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class PromotionCard extends ConsumerWidget {
  const PromotionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final assessmentResultAsync = ref.watch(latestAssessmentResultProvider);

    // Show assessment results for guest users, promotion for authenticated users
    if (authState.isGuestUser) {
      return _buildAssessmentResultCard(context, ref, assessmentResultAsync);
    } else {
      // return _buildPromotionCard(context);
      return const SizedBox.shrink(); // Return empty widget for now
    }
  }

  Widget _buildAssessmentResultCard(BuildContext context, WidgetRef ref, AsyncValue assessmentResultAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: assessmentResultAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading assessment results...'),
            ],
          ),
          error: (error, stack) => Row(
            children: [
              Icon(Icons.error, color: Colors.red[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error loading assessment: $error',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            ],
          ),
          data: (assessmentResult) {
            if (assessmentResult == null) {
              return Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[400]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No assessment results found. Take the assessment to get personalized recommendations.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Assessment Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${assessmentResult.overallScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stage breakdown
                ...assessmentResult.stageScores.entries.map((entry) {
                  final stage = entry.key;
                  final score = entry.value;
                  final total = assessmentResult.totalQuestionsPerStage[stage] ?? 0;
                  final percentage = total > 0 ? (score / total) * 100 : 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getStageTitle(stage),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${score}/${total} (${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: percentage >= 75 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Text(
                  'Register to access personalized courses based on your results',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: () => context.go('/signup'),
                  fillColor: AppColors.copBlue,
                  text: "Register to Access Courses",
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.promoCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Start",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Find the right level and start your first free\ncrash course",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 19,
                      color: AppColors.copBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "At Millpress",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    onPressed: () {},
                    fillColor: AppColors.copBlue,
                    text: "Find Levels",
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/promo_illustration.svg',
              width: 130,
              height: 130,
            ),
          ],
        ),
      ),
    );
  }

  String _getStageTitle(String stage) {
    switch (stage) {
      case 'letter_recognition':
        return 'Letter Recognition';
      case 'word_recognition':
        return 'Word Recognition';
      case 'sentence_comprehension':
        return 'Sentence Comprehension';
      case 'writing_ability':
        return 'Writing Ability';
      default:
        return stage;
    }
  }
}
