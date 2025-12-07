import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:milpress/features/on_boarding/models/on_boarding_quiz_model.dart';
import '../models/assessment_config.dart';

class AssessmentState {
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final List<bool> userAnswers;
  final bool isComplete;
  final bool isStageComplete;
  final AssessmentConfig config;
  final bool isTransitioning;
  final Map<int, int> questionAttempts; 
  final Map<int, List<bool>> questionAttemptHistory;
  final int maxRetriesPerQuestion;
  final bool allowRetries;

  AssessmentState({
    required this.questions,
    required this.currentIndex,
    required this.userAnswers,
    required this.isComplete,
    required this.isStageComplete,
    required this.config,
    this.isTransitioning = false,
    this.questionAttempts = const {},
    this.questionAttemptHistory = const {},
    this.maxRetriesPerQuestion = 0,
    this.allowRetries = false,
  });

  AssessmentState copyWith({
    List<Map<String, dynamic>>? questions,
    int? currentIndex,
    List<bool>? userAnswers,
    bool? isComplete,
    bool? isStageComplete,
    AssessmentConfig? config,
    bool? isTransitioning,
    Map<int, int>? questionAttempts,
    Map<int, List<bool>>? questionAttemptHistory,
    int? maxRetriesPerQuestion,
    bool? allowRetries,
  }) {
    return AssessmentState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isComplete: isComplete ?? this.isComplete,
      isStageComplete: isStageComplete ?? this.isStageComplete,
      config: config ?? this.config,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      questionAttempts: questionAttempts ?? this.questionAttempts,
      questionAttemptHistory: questionAttemptHistory ?? this.questionAttemptHistory,
      maxRetriesPerQuestion: maxRetriesPerQuestion ?? this.maxRetriesPerQuestion,
      allowRetries: allowRetries ?? this.allowRetries,
    );
  }

  bool get isCurrentStageSuccessful {
    if (!isStageComplete) return false;
    final correctAnswers = userAnswers.where((answer) => answer).length;
    return correctAnswers >= questions.length * 0.75; // 75% threshold
  }

  int get currentStageScore {
    if (!isStageComplete) return 0;
    return userAnswers.where((answer) => answer).length;
  }

  bool get shouldShowIntermediateResult {
    return config.isOnboarding && 
           config.showIntermediateResults && 
           isStageComplete && 
           !isComplete;
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier(List<Map<String, dynamic>> questions, AssessmentConfig config) 
      : super(AssessmentState(
          questions: questions,
          currentIndex: 0,
          userAnswers: [],
          isComplete: false,
          isStageComplete: false,
          config: config,
          maxRetriesPerQuestion: config.maxRetriesPerQuestion,
          allowRetries: config.allowRetries,
        ));

  Future<void> answerCurrent(bool isCorrect, {int attemptNumber = 1}) async {
    if (state.isComplete) return;

    if (isCorrect) {
      // Record final answer and move to next question
      final newAnswers = List<bool>.from(state.userAnswers)..add(true);
      final isLastQuestion = state.currentIndex == state.questions.length - 1;

      if (isLastQuestion) {
        // Stage/Quiz is complete
        final score = newAnswers.where((a) => a).length;
        final isSuccess = score >= state.questions.length * 0.75;

        if (state.config.isOnboarding) {
          // Update config with new stage scores
          final updatedConfig = state.config.updateStageScores(
            state.config.stage!,
            score,
            state.questions.length,
          );

          state = state.copyWith(
            userAnswers: newAnswers,
            isStageComplete: true,
            config: updatedConfig,
          );

          // Call stage complete callback
          state.config.onStageComplete?.call(
            state.config.getCompletionData(
              score: score,
              totalQuestions: state.questions.length,
              isSuccess: isSuccess,
            ),
          );
        } else {
          // Lesson quiz complete
          state = state.copyWith(
            userAnswers: newAnswers,
            isComplete: true,
          );

          // Call quiz complete callback
          state.config.onQuizComplete?.call(
            state.config.getCompletionData(
              score: score,
              totalQuestions: state.questions.length,
              isSuccess: isSuccess,
            ),
          );
        }
      } else {
        // Move to next question
        state = state.copyWith(
          currentIndex: state.currentIndex + 1,
          userAnswers: newAnswers,
        );
      }
    } else {
      // Check if retries are available
      if (state.allowRetries && attemptNumber < state.maxRetriesPerQuestion) {
        // Stay on same question, increment attempt counter
        // Update attempt history
        final newAttemptHistory = Map<int, List<bool>>.from(state.questionAttemptHistory);
        newAttemptHistory[state.currentIndex] = List<bool>.from(newAttemptHistory[state.currentIndex] ?? [])..add(false);
        state = state.copyWith(
          questionAttempts: Map<int, int>.from(state.questionAttempts)..update(state.currentIndex, (value) => value + 1),
          questionAttemptHistory: newAttemptHistory,
        );
      } else {
        // No more retries, record final answer as false
        final newAnswers = List<bool>.from(state.userAnswers)..add(false);
        final isLastQuestion = state.currentIndex == state.questions.length - 1;

        if (isLastQuestion) {
          // Stage/Quiz is complete
          final score = newAnswers.where((a) => a).length;
          final isSuccess = score >= state.questions.length * 0.75;

          if (state.config.isOnboarding) {
            // Update config with new stage scores
            final updatedConfig = state.config.updateStageScores(
              state.config.stage!,
              score,
              state.questions.length,
            );

            state = state.copyWith(
              userAnswers: newAnswers,
              isStageComplete: true,
              config: updatedConfig,
            );

            // Call stage complete callback
            state.config.onStageComplete?.call(
              state.config.getCompletionData(
                score: score,
                totalQuestions: state.questions.length,
                isSuccess: isSuccess,
              ),
            );
          } else {
            // Lesson quiz complete
            state = state.copyWith(
              userAnswers: newAnswers,
              isComplete: true,
            );

            // Call quiz complete callback
            state.config.onQuizComplete?.call(
              state.config.getCompletionData(
                score: score,
                totalQuestions: state.questions.length,
                isSuccess: isSuccess,
              ),
            );
          }
        } else {
          // Move to next question
          state = state.copyWith(
            currentIndex: state.currentIndex + 1,
            userAnswers: newAnswers,
          );
        }
      }
    }
  }

  void reset() {
    state = AssessmentState(
      questions: state.questions,
      currentIndex: 0,
      userAnswers: [],
      isComplete: false,
      isStageComplete: false,
      config: state.config,
      questionAttempts: const {},
      questionAttemptHistory: const {},
      maxRetriesPerQuestion: state.maxRetriesPerQuestion,
      allowRetries: state.allowRetries,
    );
  }

  void continueToNextStage() {
    if (state.config.isOnboarding && state.isStageComplete) {
      // Reset for next stage
      state = state.copyWith(
        currentIndex: 0,
        userAnswers: [],
        isStageComplete: false,
      );
    }
  }

  Future<void> handleStageCompletion() async {
    if (!state.isStageComplete) return;

    if (state.config.isLessonQuiz) {
      // For lesson quiz, handle lesson completion logic
      final lessonId = state.config.lessonId;
      if (lessonId != null) {
        // TODO: Implement lesson completion logic
        // This would involve updating lesson progress in Hive
        // and navigating to the lesson complete screen
      }
    }
    // For onboarding, the callback will handle navigation
  }
}

final assessmentFlowProvider = StateNotifierProvider.family<AssessmentNotifier, AssessmentState, (List<Map<String, dynamic>>, AssessmentConfig)>(
  (ref, params) => AssessmentNotifier(params.$1, params.$2),
); 