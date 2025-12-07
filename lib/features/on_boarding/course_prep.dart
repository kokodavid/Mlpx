import 'package:flutter/material.dart';
import 'package:milpress/features/on_boarding/providers/onboarding_quiz_providers.dart';
import 'package:milpress/utils/app_colors.dart';
import '../widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/widgets/audio_play_button.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import 'package:milpress/providers/audio_service_provider.dart';
import 'package:milpress/features/assessment/assessment_screen.dart';
import 'package:milpress/features/assessment/models/assessment_config.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/course/providers/course_provider.dart';

class CoursePrepScreen extends ConsumerStatefulWidget {
  const CoursePrepScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoursePrepScreen> createState() => _CoursePrepScreenState();
}

class _CoursePrepScreenState extends ConsumerState<CoursePrepScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }



  void _startAssessment(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await ref.read(prepareOnboardingAssessmentProvider.future);

      // Prefetch course suggestions (audio will be downloaded on-demand)
      await ref.read(assessmentCourseSuggestionsProvider.future);

      // Prefetch audio files for all assessment stages
      print('CoursePrep: Starting assessment preparation...');
      print('CoursePrep: Total questions: ${questions.length}');
      
      // Group questions by stage for logging
      final questionsByStage = <String, List<Map<String, dynamic>>>{};
      for (final question in questions) {
        final stage = question['stage'] as String;
        questionsByStage.putIfAbsent(stage, () => []).add(question);
      }
      
      print('CoursePrep: Questions by stage:');
      questionsByStage.forEach((stage, stageQuestions) {
        final audioQuestions = stageQuestions.where((q) => q['sound_file_url'] != null && q['sound_file_url'].toString().isNotEmpty).length;
        print('  - $stage: ${stageQuestions.length} questions (${audioQuestions} with audio)');
      });
      
      // Show prefetching progress
      setState(() {
        _error = 'Preparing audio files for assessment and result screens...';
      });
      
      print('CoursePrep: Starting audio prefetching for all stages and result screens...');
      // Prefetch audio files for all questions and result screens using the function
      await prefetchAssessmentAudio(questions, ref);
      print('CoursePrep: Audio prefetching completed for all stages and result screens');

      final config = AssessmentConfig.onboarding(
        stage: 'letter_recognition',
        onStageComplete: (result) {
          context.go(
            '/result',
            extra: {
              'isSuccess': result['isSuccess'],
              'score': result['score'],
              'totalQuestions': result['totalQuestions'],
              'stage': result['stage'],
              'stageScores': result['stageScores'],
              'totalQuestionsPerStage': result['totalQuestionsPerStage'],
              'isFinalResult': result['isFinalResult'],
              'allQuestions': questions,
            },
          );
        },
      );

      if (mounted) {
        // Stop audio session before navigating
        await ref.read(audioSessionProvider.notifier).stopSession('course_prep_screen');
        context.go(
          '/assessment',
          extra: {
            'questions': questions.where((q) => q['stage'] == 'letter_recognition').toList(),
            'config': config,
            'allQuestions': questions,
          },
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error preparing assessment: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Computed loading state
  bool get _isInLoadingState => _isLoading || (_error != null && _error!.contains('Preparing audio files'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              const Center(
                child: const AudioPlayButton(
                  screenId: 'course_prep_screen',
                  lottieAsset: 'assets/waveworm.json',
                  audioStoragePath: 'assesment.mp3',
                  backgroundColor: AppColors.successColor,
                  showReplayButton: true,
                  showClearCacheButton: true,
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/raise_hand.png', height: 160),
                      const SizedBox(height: 20),
                      const Text(
                        'Hi there,\nwelcome to Milpress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You will be assessed in the next steps to personalize your learning experience!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),

                      // Error message for non-loading errors only
                      if (_error != null && !_error!.contains('Preparing audio files'))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _isInLoadingState
                  ? Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        if (_error != null && _error!.contains('Preparing audio files'))
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    )
                  : CustomButton(
                      text: 'Start Assessment',
                      onPressed: () => _startAssessment(context, ref),
                      isFilled: true,
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
