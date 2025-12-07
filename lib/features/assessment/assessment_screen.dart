import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/assessment_flow_provider.dart';
import 'package:milpress/providers/audio_player_provider.dart';
import 'package:milpress/providers/audio_session_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/progress_widget.dart';
import 'package:milpress/features/widgets/listen_section.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/shared/widgets/confirmation_dialog.dart';
import 'widgets/letter_recognition_options.dart';
import 'widgets/word_recognition_options.dart';
import 'widgets/sentence_comprehension_options.dart';
import 'widgets/writing_ability_options.dart';
import 'models/assessment_config.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/on_boarding/providers/onboarding_quiz_providers.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> questions;
  final AssessmentConfig config;
  final List<Map<String, dynamic>>? allQuestions;

  const AssessmentScreen({
    Key? key, 
    required this.questions,
    required this.config,
    this.allQuestions,
  }) : super(key: key);

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  bool _isNavigating = false;

  @override
  void dispose() {
    _stopAllAudioSessions();
    super.dispose();
  }

  Future<void> _stopAllAudioSessions() async {
    try {
      for (final question in widget.questions) {
        final screenId = 'assessment_screen_${question['id']}';
        await ref.read(audioSessionProvider.notifier).stopSession(screenId);
      }
    } catch (e) {
      debugPrint('AssessmentScreen: Error stopping audio sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(assessmentFlowProvider((widget.questions, widget.config)));
    final flowNotifier = ref.read(assessmentFlowProvider((widget.questions, widget.config)).notifier);
    final audioState = ref.watch(audioPlayerProvider);
    final stageManager = ref.watch(stageManagerProvider);

    // Handle stage completion for onboarding - only when stage is actually complete
    if (flow.isStageComplete && !flow.isComplete && !_isNavigating) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Navigate directly with smooth transition animation
          context.pushReplacement(
            '/result',
            extra: {
              'isSuccess': flow.isCurrentStageSuccessful,
              'score': flow.currentStageScore,
              'totalQuestions': flow.questions.length,
              'stage': widget.config.stage,
              'stageScores': flow.config.stageScores,
              'totalQuestionsPerStage': flow.config.totalQuestionsPerStage,
              // Use stageManager to check if this is the last stage
              'isFinalResult': stageManager.isLast(widget.config.stage ?? ''),
              'allQuestions': widget.allQuestions,
            },
          );
        }
      });
      // Return the current assessment screen to maintain visual continuity
      return _buildAssessmentContent(flow, flowNotifier, audioState);
    }   

    // Handle other completion cases (fallback)
    if (flow.isComplete) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Assessment Complete!', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              Text('Score: ${flow.userAnswers.where((a) => a).length} / ${flow.questions.length}'),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Restart',
                onPressed: flowNotifier.reset,
                isFilled: true,
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = flow.questions[flow.currentIndex];
    final progress = flow.currentIndex / flow.questions.length;
    final questionNumber = flow.currentIndex + 1;
    final totalQuestions = flow.questions.length;


    return _buildAssessmentContent(flow, flowNotifier, audioState, currentQuestion, progress, questionNumber, totalQuestions);
  }

  Widget _buildAssessmentContent(
    AssessmentState flow,
    AssessmentNotifier flowNotifier,
    AudioPlayerState audioState, [
    Map<String, dynamic>? currentQuestion,
    double? progress,
    int? questionNumber,
    int? totalQuestions,
  ]) {
    // If we don't have the required data, return the assessment structure without content
    if (currentQuestion == null || progress == null || questionNumber == null || totalQuestions == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.config.isOnboarding 
                ? _formatStageTitle(widget.config.stage ?? 'Assessment')
                : 'Lesson Quiz',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => _showQuitConfirmationDialog(context),
            ),
          ],
        ),
        body: const SafeArea(
          child: Center(
            child: SizedBox.shrink(), // Empty but maintains layout structure
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.config.isOnboarding 
              ? _formatStageTitle(widget.config.stage ?? 'Assessment')
              : 'Lesson Quiz',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => _showQuitConfirmationDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressSection(
                progress: progress,
                questionNumber: questionNumber.toString(),
              ),
              const SizedBox(height: 8),
              Text(
                _getQuestionInstruction(currentQuestion['stage']),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_hasAudio(currentQuestion))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListenSection(
                    key: ValueKey('listen_section_${currentQuestion['id']}'),
                    soundFileUrl: currentQuestion['sound_file_url'],
                    screenId: 'assessment_screen_${currentQuestion['id']}',
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildOptionsSection(
                  context,
                  ref,
                  currentQuestion,
                  currentIndex: flow.currentIndex,
                  onOptionSelected: (isCorrect, {int? attemptNumber}) async {
                    await flowNotifier.answerCurrent(isCorrect, attemptNumber: attemptNumber ?? 1);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getQuestionInstruction(String stage) {
    switch (stage) {
      case 'letter_recognition':
        return 'Select the correct letter from this voice.';
      case 'word_recognition':
        return 'Select the correct word from this voice.';
      case 'sentence_comprehension':
        return 'Select the correct sentence that matches the audio.';
      case 'writing_ability':
        return 'Type the word you hear.';
      default:
        return 'Select the correct answer.';
    }
  }

  bool _hasAudio(Map<String, dynamic> question) {
    return question['sound_file_url'] != null && question['sound_file_url'].toString().isNotEmpty;
  }

  Widget _buildOptionsSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> question, {
    required int currentIndex,
    required void Function(bool isCorrect, {int? attemptNumber}) onOptionSelected,
  }) {
    
    switch (question['stage']) {
      case 'letter_recognition':
        return LetterRecognitionOptions(
          key: ValueKey('letter_ [38;5;244m$currentIndex [0m'),
          question: question,
          onOptionSelected: onOptionSelected,
        );
      case 'word_recognition':
        return WordRecognitionOptions(
          key: ValueKey('word_ [38;5;244m$currentIndex [0m'),
          question: question,
          onOptionSelected: onOptionSelected,
        );
      case 'sentence_comprehension':
        return SentenceComprehensionOptions(
          key: ValueKey('sentence_ [38;5;244m$currentIndex [0m'),
          question: question,
          onOptionSelected: onOptionSelected,
        );
      case 'writing_ability':
        return WritingAbilityOptions(
          key: ValueKey('writing_ [38;5;244m$currentIndex [0m'),
          question: question,
          onOptionSelected: onOptionSelected,
        );
      default:
        return const Center(child: Text('Unknown question type'));
    }
  }

  String _formatStageTitle(String stage) {
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
        // Fallback: convert snake_case to Title Case
        return stage.split('_')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
  }

  Future<void> _showQuitConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Quit Assessment?',
          message: 'Are you sure you want to quit? Your progress will be lost.',
          confirmText: 'Quit',
          cancelText: 'Back',
          isDestructive: true,
          onConfirm: () {
            // Navigate to welcome screend
            context.go('/welcome');
          },
          onCancel: () {
            // Just close the dialog - no additional action needed
          },
        );
      },
    );
  }
}
