import 'package:flutter/material.dart';
import 'package:milpress/features/on_boarding/profile_checker.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/features/widgets/audio_play_button.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/assessment/models/assessment_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/onboarding_quiz_providers.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/course/course_widgets/course_suggestion_card.dart';
import 'package:milpress/features/course/course_models/course_model.dart';
import 'package:milpress/features/assessment/providers/assessment_result_provider.dart';
import 'package:milpress/features/assessment/services/assessment_result_service.dart';
import 'providers/recommended_course_provider.dart';
import 'package:milpress/providers/audio_service_provider.dart';
import 'package:milpress/providers/audio_session_provider.dart';

class ResultScreen extends ConsumerWidget {
  final bool isSuccess;
  final int score;
  final int totalQuestions;
  final String stage;
  final Map<String, int>? stageScores;
  final Map<String, int>? totalQuestionsPerStage;
  final bool isFinalResult;
  final List<Map<String, dynamic>>? allQuestions;

  const ResultScreen({
    Key? key,
    required this.isSuccess,
    required this.score,
    required this.totalQuestions,
    required this.stage,
    this.stageScores,
    this.totalQuestionsPerStage,
    this.isFinalResult = false,
    this.allQuestions,
  }) : super(key: key);

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
        return 'Assessment';
    }
  }

  double _calculateOverallScore() {
    if (stageScores == null || totalQuestionsPerStage == null) return 0;
    int totalScore = 0;
    int totalPossible = 0;
    stageScores!.forEach((stage, score) {
      totalScore += score;
      totalPossible += totalQuestionsPerStage![stage] ?? 0;
    });
    return totalPossible > 0 ? (totalScore / totalPossible) * 100 : 0;
  }

  String _getCourseTypeForStage(String stage) {
    switch (stage) {
      case 'letter_recognition':
        return 'Letter';
      case 'word_recognition':
        return 'Word';
      case 'sentence_comprehension':
        return 'Sentence';
      case 'writing_ability':
        return 'Writing';
      default:
        return 'Letter'; // Default fallback
    }
  }

  CourseModel? _getSuggestedCourse(
      Map<String, List<CourseModel>> coursesByType, String stage) {
    final courseType = _getCourseTypeForStage(stage);
    final courses = coursesByType[courseType];

    if (courses != null && courses.isNotEmpty) {
      // Return the first available course of the matching type
      return courses.first;
    }

    return null;
  }

  Future<void> _saveAssessmentResult(WidgetRef ref) async {
    if (stageScores == null || totalQuestionsPerStage == null) {
      print('Cannot save assessment result: missing stage scores or totals');
      return;
    }

    try {
      final service = ref.read(assessmentResultServiceProvider);
      final result = service.createAssessmentResult(
        stageScores: stageScores!,
        totalQuestionsPerStage: totalQuestionsPerStage!,
      );

      await ref.read(saveAssessmentResultProvider(result).future);
      print('Assessment result saved successfully: ${result.id}');
    } catch (e) {
      print('Error saving assessment result: $e');
    }
  }

  void _handleContinue(BuildContext context, WidgetRef ref) {
    final stageManager = ref.read(stageManagerProvider);
    final nextStage = stageManager.nextStage(stage);
    if (nextStage == null) {
      // Final stage, do nothing or pop, but do not navigate to profile checker
      return;
    }
    // Get all questions for the next stage
    final nextStageQuestions =
        (allQuestions ?? []).where((q) => q['stage'] == nextStage).toList();
    if (nextStageQuestions.isEmpty) {
      // No more questions, do nothing
      return;
    }
    // Prepare updated scores
    final updatedStageScores = Map<String, int>.from(stageScores ?? {});
    updatedStageScores[stage] = score;
    final updatedTotals = Map<String, int>.from(totalQuestionsPerStage ?? {});
    updatedTotals[stage] = totalQuestions;
    // Navigate to next assessment stage
    context.go(
      '/assessment',
      extra: {
        'questions': nextStageQuestions,
        'config': AssessmentConfig.onboarding(
          stage: nextStage,
          stageScores: updatedStageScores,
          totalQuestionsPerStage: updatedTotals,
          // onStageComplete will be set in the new AssessmentScreen
        ),
        'allQuestions': allQuestions,
      },
    );
  }

  void _handleRetryStage(BuildContext context, WidgetRef ref, String stageToRetry) async {
    // Get questions for the specific stage to retry
    final stageQuestions = (allQuestions ?? []).where((q) => q['stage'] == stageToRetry).toList();
    if (stageQuestions.isEmpty) {
      print('No questions found for stage: $stageToRetry');
      return;
    }

    // Clear the progress for this specific stage by removing it from stageScores
    final updatedStageScores = Map<String, int>.from(stageScores ?? {});
    updatedStageScores.remove(stageToRetry); // Remove the stage score to clear progress
    
    final updatedTotals = Map<String, int>.from(totalQuestionsPerStage ?? {});
    updatedTotals.remove(stageToRetry); // Also remove the total questions for this stage

    // Clear any saved assessment results to ensure a fresh start
    try {
      final service = ref.read(assessmentResultServiceProvider);
      await service.clearAssessmentResult();
      print('Cleared previous assessment result for fresh retry');
    } catch (e) {
      print('Error clearing assessment result: $e');
      // Continue anyway, as this is not critical
    }

    // Navigate back to assessment with cleared progress for this stage
    context.go(
      '/assessment',
      extra: {
        'questions': stageQuestions,
        'config': AssessmentConfig.onboarding(
          stage: stageToRetry,
          stageScores: updatedStageScores,
          totalQuestionsPerStage: updatedTotals,
          // onStageComplete will be set in the new AssessmentScreen
        ),
        'allQuestions': allQuestions,
      },
    );
  }

  void _handleStartCourse(BuildContext context, WidgetRef ref, CourseModel course) {
    // Store the recommended course for post-authentication navigation
    ref.read(recommendedCourseProvider.notifier).setRecommendedCourse(course);
    
    // Navigate to signup screen
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageManager = ref.watch(stageManagerProvider);
    final percentage =
        totalQuestions > 0 ? (score / totalQuestions * 100).round() : 0;
    final overallScore = _calculateOverallScore();
    final nextStage = stageManager.nextStage(stage);
    final isLast = nextStage == null;

    // Check if we should show course suggestion (score < 100%)
    final shouldShowCourseSuggestion = percentage < 100 && !isLast;

    // Get course suggestions if needed
    final courseSuggestionsAsync = shouldShowCourseSuggestion
        ? ref.watch(assessmentCourseSuggestionsProvider)
        : null;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header row with title on left and audio button on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isLast ? 'Assessment Complete!' : 'Stage Complete!',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AudioPlayButton(
                    screenId: 'result_screen',
                    lottieAsset: 'assets/waveworm.json',
                    audioStoragePath: isLast
                        ? 'complete_assesment.mp3'
                        : (isSuccess
                            ? 'stage_complete.mp3'
                            : 'stage_retry.mp3'),
                    backgroundColor: isLast
                        ? AppColors.primaryColor
                        : (isSuccess
                            ? AppColors.successColor
                            : AppColors.errorColor),
                    height: 28,
                    borderRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLast) ...[
                Expanded(
                  child: ListView(
                    children: [
                      // Overall Score Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overall Assessment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${stageScores?.values.fold(0, (sum, score) => sum + score) ?? 0} out of ${totalQuestionsPerStage?.values.fold(0, (sum, total) => sum + total) ?? 0} questions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${overallScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: overallScore >= 75
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (stageScores != null && totalQuestionsPerStage != null)
                        ...stageScores!.entries.map((entry) {
                          final stage = entry.key;
                          final stageScore = entry.value;
                          final stageTotal =
                              totalQuestionsPerStage![stage] ?? 0;
                          final stagePercentage = stageTotal > 0
                              ? (stageScore / stageTotal) * 100
                              : 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getStageTitle(stage),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '$stageScore out of $stageTotal questions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${stagePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: stagePercentage >= 75
                                        ? AppColors.successColor
                                        : AppColors.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Score display section
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                isSuccess
                                    ? 'assets/success.svg'
                                    : 'assets/error.svg',
                                height: 150,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isSuccess
                                    ? 'Congratulations!'
                                    : 'Keep Practicing!',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getStageTitle(stage),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                ),
                              ),                             
                              const SizedBox(height: 5),
                              Text(
                                'Score ($percentage%)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSuccess
                                      ? AppColors.successColor
                                      : AppColors.errorColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (shouldShowCourseSuggestion &&
                            courseSuggestionsAsync != null) ...[
                          const SizedBox(height: 20),
                          courseSuggestionsAsync!.when(
                            data: (coursesByType) {
                              final suggestedCourse =
                                  _getSuggestedCourse(coursesByType, stage);
                              if (suggestedCourse != null) {
                                                              return CourseSuggestionCard(
                                course: suggestedCourse,
                                onTakeCourse: () {
                                  _handleStartCourse(context, ref, suggestedCourse);
                                },
                                onRetryAssessment: () {
                                  _handleRetryStage(context, ref, stage);
                                },
                              );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: const Text(
                                    'No course suggestions available for this stage.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                );
                              }
                            },
                            loading: () => Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading course suggestions...'),
                                ],
                              ),
                            ),
                            error: (error, stack) => Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Error loading course suggestions: $error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (!shouldShowCourseSuggestion ||
                  (shouldShowCourseSuggestion &&
                      courseSuggestionsAsync != null &&
                      courseSuggestionsAsync!.hasValue &&
                      _getSuggestedCourse(
                              courseSuggestionsAsync!.value!, stage) ==
                          null)) ...[
                CustomButton(
                  text: isLast ? 'Save to profile' : 'Continue',
                  onPressed: () async {
                    if (isLast) {
                      await _saveAssessmentResult(ref);
                      
                      try {
                        
                        final currentSession = ref.read(audioSessionProvider).activeScreenId;
                        if (currentSession != null) {
                          await ref.read(audioSessionProvider.notifier).stopSession(currentSession);
                        }
                        
                        await ref.read(audioServiceProvider.notifier).clearCache();
                        
                      } catch (e) {
                        debugPrint('Error clearing audio cache: $e');
                      }
                      
                      context.go('/profile_checker');
                    } else {
                      _handleContinue(context, ref);
                    }
                  },
                  isFilled: true,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
