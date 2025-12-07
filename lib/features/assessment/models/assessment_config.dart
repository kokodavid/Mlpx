enum AssessmentType {
  onboarding,  // Staged with intermediate results
  lessonQuiz,  // Continuous without intermediate results
}

class AssessmentConfig {
  final AssessmentType type;
  final String? stage; // For onboarding: 'letter_recognition', 'word_recognition', etc.
  final String? lessonId; // For lesson quiz
  final bool showIntermediateResults;
  final Function(Map<String, dynamic>)? onStageComplete; // For onboarding
  final Function(Map<String, dynamic>)? onQuizComplete; // For lesson quiz
  final Map<String, int>? stageScores; // For onboarding: track scores across stages
  final Map<String, int>? totalQuestionsPerStage; // For onboarding: track total questions per stage
  final int maxRetriesPerQuestion; // 0 = no retries, 1 = one retry, etc.
  final bool allowRetries;
  final RetryStrategy retryStrategy; 

  const AssessmentConfig({
    required this.type,
    this.stage,
    this.lessonId,
    this.showIntermediateResults = true,
    this.onStageComplete,
    this.onQuizComplete,
    this.stageScores,
    this.totalQuestionsPerStage,
    this.maxRetriesPerQuestion = 0,
    this.allowRetries = false,
    this.retryStrategy = RetryStrategy.immediate,
  });

  // Factory constructor for onboarding assessment
  factory AssessmentConfig.onboarding({
    required String stage,
    Function(Map<String, dynamic>)? onStageComplete,
    Map<String, int>? stageScores,
    Map<String, int>? totalQuestionsPerStage,
    int maxRetriesPerQuestion = 0,
    bool allowRetries = false,
    RetryStrategy retryStrategy = RetryStrategy.immediate,
  }) {
    return AssessmentConfig(
      type: AssessmentType.onboarding,
      stage: stage,
      showIntermediateResults: true,
      onStageComplete: onStageComplete,
      stageScores: stageScores ?? {},
      totalQuestionsPerStage: totalQuestionsPerStage ?? {},
      maxRetriesPerQuestion: maxRetriesPerQuestion,
      allowRetries: allowRetries,
      retryStrategy: retryStrategy,
    );
  }

  // Factory constructor for lesson quiz
  factory AssessmentConfig.lessonQuiz({
    required String lessonId,
    Function(Map<String, dynamic>)? onQuizComplete,
    int maxRetriesPerQuestion = 0,
    bool allowRetries = false,
    RetryStrategy retryStrategy = RetryStrategy.immediate,
  }) {
    return AssessmentConfig(
      type: AssessmentType.lessonQuiz,
      lessonId: lessonId,
      showIntermediateResults: false,
      onQuizComplete: onQuizComplete,
      maxRetriesPerQuestion: maxRetriesPerQuestion,
      allowRetries: allowRetries,
      retryStrategy: retryStrategy,
    );
  }

  // Helper methods
  bool get isOnboarding => type == AssessmentType.onboarding;
  bool get isLessonQuiz => type == AssessmentType.lessonQuiz;

  // Create updated config with new stage scores
  AssessmentConfig copyWith({
    AssessmentType? type,
    String? stage,
    String? lessonId,
    bool? showIntermediateResults,
    Function(Map<String, dynamic>)? onStageComplete,
    Function(Map<String, dynamic>)? onQuizComplete,
    Map<String, int>? stageScores,
    Map<String, int>? totalQuestionsPerStage,
    int? maxRetriesPerQuestion,
    bool? allowRetries,
    RetryStrategy? retryStrategy,
  }) {
    return AssessmentConfig(
      type: type ?? this.type,
      stage: stage ?? this.stage,
      lessonId: lessonId ?? this.lessonId,
      showIntermediateResults: showIntermediateResults ?? this.showIntermediateResults,
      onStageComplete: onStageComplete ?? this.onStageComplete,
      onQuizComplete: onQuizComplete ?? this.onQuizComplete,
      stageScores: stageScores ?? this.stageScores,
      totalQuestionsPerStage: totalQuestionsPerStage ?? this.totalQuestionsPerStage,
      maxRetriesPerQuestion: maxRetriesPerQuestion ?? this.maxRetriesPerQuestion,
      allowRetries: allowRetries ?? this.allowRetries,
      retryStrategy: retryStrategy ?? this.retryStrategy,
    );
  }

  // Update stage scores for onboarding flow
  AssessmentConfig updateStageScores(String stage, int score, int totalQuestions) {
    if (!isOnboarding) return this;

    final updatedScores = Map<String, int>.from(stageScores ?? {});
    updatedScores[stage] = score;

    final updatedTotal = Map<String, int>.from(totalQuestionsPerStage ?? {});
    updatedTotal[stage] = totalQuestions;

    return copyWith(
      stageScores: updatedScores,
      totalQuestionsPerStage: updatedTotal,
    );
  }

  // Get completion data for callbacks
  Map<String, dynamic> getCompletionData({
    required int score,
    required int totalQuestions,
    required bool isSuccess,
  }) {
    final baseData = {
      'score': score,
      'totalQuestions': totalQuestions,
      'isSuccess': isSuccess,
    };

    if (isOnboarding) {
      return {
        ...baseData,
        'stage': stage,
        'stageScores': stageScores,
        'totalQuestionsPerStage': totalQuestionsPerStage,
        'isFinalResult': stage == 'writing_ability',
      };
    } else {
      return {
        ...baseData,
        'lessonId': lessonId,
      };
    }
  }
}

enum RetryStrategy {
  immediate,     // Show retry button immediately after wrong answer
  afterHint,    // Show hint first, then allow retry
  progressive,  // Increase difficulty or change options after each retry
  limited,      // Allow N retries then move on regardless
} 