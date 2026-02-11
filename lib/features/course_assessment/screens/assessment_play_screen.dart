import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/assessment_v2_composites.dart';
import '../models/question_model.dart';
import '../providers/course_assessment_providers.dart';
import '../widgets/assessment_feedback.dart';
import '../widgets/question_renderer.dart';

class _PlayableSublevel {
  final String id;
  final String title;
  final String displayLetter;
  final String questionType;
  final List<AssessmentQuestion> questions;

  const _PlayableSublevel({
    required this.id,
    required this.title,
    required this.displayLetter,
    required this.questionType,
    required this.questions,
  });
}

class _SublevelScore {
  int correct = 0;
  int total = 0;
}

class AssessmentPlayScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentPlayScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  ConsumerState<AssessmentPlayScreen> createState() =>
      _AssessmentPlayScreenState();
}

class _AssessmentPlayScreenState extends ConsumerState<AssessmentPlayScreen> {
  int _currentSublevelIndex = 0;
  int _currentQuestionIndex = 0;
  bool _showBreaker = false;
  bool _showFinalResults = false;
  bool _isResetScheduled = false;

  /// Scores per sublevel id.
  final Map<String, _SublevelScore> _sublevelScores = {};
  final Set<String> _scoredQuestionKeys = <String>{};

  _SublevelScore _scoreFor(String sublevelId) =>
      _sublevelScores.putIfAbsent(sublevelId, () => _SublevelScore());

  int get _totalCorrect =>
      _sublevelScores.values.fold(0, (sum, s) => sum + s.correct);

  int get _totalAnswered =>
      _sublevelScores.values.fold(0, (sum, s) => sum + s.total);

  String _scoreKeyFor({
    required String sublevelId,
    required int questionIndex,
  }) {
    return '$sublevelId:$questionIndex';
  }

  void _resetFlowState() {
    _currentSublevelIndex = 0;
    _currentQuestionIndex = 0;
    _showBreaker = false;
    _showFinalResults = false;
    _sublevelScores.clear();
    _scoredQuestionKeys.clear();
  }

  bool _isFlowStateValid(List<_PlayableSublevel> sublevels) {
    if (sublevels.isEmpty) {
      return false;
    }

    if (_currentSublevelIndex < 0 ||
        _currentSublevelIndex >= sublevels.length) {
      return false;
    }

    final questions = sublevels[_currentSublevelIndex].questions;
    if (questions.isEmpty) {
      return false;
    }

    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= questions.length) {
      return false;
    }

    return true;
  }

  bool get _isFlowAtInitialState {
    return _currentSublevelIndex == 0 &&
        _currentQuestionIndex == 0 &&
        !_showBreaker &&
        !_showFinalResults &&
        _sublevelScores.isEmpty &&
        _scoredQuestionKeys.isEmpty;
  }

  void _scheduleResetToInitialStateIfNeeded() {
    if (_isResetScheduled || _isFlowAtInitialState) {
      return;
    }

    _isResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isResetScheduled = false;
      if (!mounted) {
        return;
      }
      setState(_resetFlowState);
    });
  }

  void _scheduleFlowResetIfNeeded(List<_PlayableSublevel> sublevels) {
    if (_isResetScheduled || _isFlowStateValid(sublevels)) {
      return;
    }

    _isResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isResetScheduled = false;
      if (!mounted) {
        return;
      }
      setState(_resetFlowState);
    });
  }

  int _totalQuestionCount(List<_PlayableSublevel> sublevels) =>
      sublevels.fold(0, (sum, sl) => sum + sl.questions.length);

  int _questionsCompletedSoFar(List<_PlayableSublevel> sublevels) {
    var count = 0;
    for (var i = 0; i < _currentSublevelIndex; i++) {
      count += sublevels[i].questions.length;
    }
    count += _currentQuestionIndex;
    return count;
  }

  void _recordScoreForCurrentQuestion({
    required bool isCorrect,
    required String sublevelId,
  }) {
    final key = _scoreKeyFor(
      sublevelId: sublevelId,
      questionIndex: _currentQuestionIndex,
    );

    if (_scoredQuestionKeys.contains(key)) {
      return;
    }

    _scoredQuestionKeys.add(key);
    final score = _scoreFor(sublevelId);
    score.total++;
    if (isCorrect) {
      score.correct++;
    }
  }

  void _onAnswerChecked(bool isCorrect, List<_PlayableSublevel> sublevels) {
    if (_currentSublevelIndex < 0 ||
        _currentSublevelIndex >= sublevels.length) {
      return;
    }

    final currentSublevel = sublevels[_currentSublevelIndex];
    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= currentSublevel.questions.length) {
      return;
    }

    // Score each question once, even if a question type allows retries.
    _recordScoreForCurrentQuestion(
      isCorrect: isCorrect,
      sublevelId: currentSublevel.id,
    );

    // Only advance on correct answer.
    if (!isCorrect) {
      return;
    }

    final answeredSublevelIndex = _currentSublevelIndex;
    final answeredQuestionIndex = _currentQuestionIndex;
    final questionCount = currentSublevel.questions.length;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        // Ignore delayed callback if user state has already moved.
        if (_currentSublevelIndex != answeredSublevelIndex ||
            _currentQuestionIndex != answeredQuestionIndex) {
          return;
        }

        if (_currentQuestionIndex < questionCount - 1) {
          _currentQuestionIndex++;
        } else {
          _showBreaker = true;
        }
      });
    });
  }

  void _onBreakerNext(List<_PlayableSublevel> sublevels) {
    setState(() {
      _showBreaker = false;
      if (_currentSublevelIndex < sublevels.length - 1) {
        _currentSublevelIndex++;
        _currentQuestionIndex = 0;
      } else {
        _showFinalResults = true;
      }
    });
  }

  void _onBreakerReview(List<_PlayableSublevel> sublevels) {
    if (_currentSublevelIndex < 0 ||
        _currentSublevelIndex >= sublevels.length) {
      return;
    }

    final currentSublevelId = sublevels[_currentSublevelIndex].id;
    setState(() {
      _showBreaker = false;
      _currentQuestionIndex = 0;
      _sublevelScores[currentSublevelId] = _SublevelScore();
      _scoredQuestionKeys.removeWhere(
        (key) => key.startsWith('$currentSublevelId:'),
      );
    });
  }

  List<_PlayableSublevel> _mapToPlayableSublevels(
    AssessmentWithLevels? data,
  ) {
    if (data == null) {
      return const [];
    }

    final playableSublevels = <_PlayableSublevel>[];

    for (final level in data.levels) {
      for (final sublevel in level.sublevels) {
        final parsedQuestions = <AssessmentQuestion>[];

        for (var questionIndex = 0;
            questionIndex < sublevel.questions.length;
            questionIndex++) {
          final question = _tryParseQuestion(
            sublevel.questions[questionIndex],
            sublevelId: sublevel.id,
            questionIndex: questionIndex,
          );
          if (question != null) {
            parsedQuestions.add(question);
          }
        }

        if (parsedQuestions.isEmpty) {
          debugPrint(
            'AssessmentPlayScreen: skipping sublevel ${sublevel.id} - no valid questions',
          );
          continue;
        }

        final questionType = parsedQuestions.first.type;
        final hasMixedTypes =
            parsedQuestions.any((q) => q.type != questionType);
        if (hasMixedTypes) {
          debugPrint(
            'AssessmentPlayScreen: mixed question types in sublevel ${sublevel.id}',
          );
        }

        playableSublevels.add(
          _PlayableSublevel(
            id: sublevel.id,
            title: sublevel.title,
            displayLetter: _deriveDisplayLetter(sublevel.title),
            questionType: questionType,
            questions: parsedQuestions,
          ),
        );
      }
    }

    return playableSublevels;
  }

  AssessmentQuestion? _tryParseQuestion(
    dynamic rawQuestion, {
    required String sublevelId,
    required int questionIndex,
  }) {
    Map<String, dynamic>? map;

    if (rawQuestion is Map<String, dynamic>) {
      map = rawQuestion;
    } else if (rawQuestion is Map) {
      map = rawQuestion.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else if (rawQuestion is String) {
      try {
        final decoded = jsonDecode(rawQuestion);
        if (decoded is Map) {
          map = decoded.map((key, value) => MapEntry(key.toString(), value));
        } else {
          debugPrint(
            'AssessmentPlayScreen: decoded question is not a map in sublevel $sublevelId at index $questionIndex',
          );
          return null;
        }
      } catch (_) {
        debugPrint(
          'AssessmentPlayScreen: invalid JSON string question in sublevel $sublevelId at index $questionIndex',
        );
        return null;
      }
    } else {
      debugPrint(
        'AssessmentPlayScreen: invalid question payload in sublevel $sublevelId at index $questionIndex',
      );
      return null;
    }

    try {
      return AssessmentQuestion.fromJson(map);
    } catch (e) {
      debugPrint(
        'AssessmentPlayScreen: failed to parse question in sublevel $sublevelId at index $questionIndex: $e',
      );
      return null;
    }
  }

  String _deriveDisplayLetter(String title) {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    if (words.length == 1) {
      final firstWord = words.first;
      if (firstWord.length >= 2) {
        return firstWord.substring(0, 2).toUpperCase();
      }
      return firstWord.toUpperCase();
    }

    return 'AA';
  }

  @override
  Widget build(BuildContext context) {
    final assessmentAsync =
        ref.watch(assessmentByIdProvider(widget.assessmentId));

    return Scaffold(
      backgroundColor: AppColors.sandyLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Assessment Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: assessmentAsync.when(
        loading: _buildLoadingState,
        error: (error, _) => _buildErrorState(error),
        data: (assessment) {
          final sublevels = _mapToPlayableSublevels(assessment);

          if (sublevels.isEmpty) {
            _scheduleResetToInitialStateIfNeeded();
            return _buildEmptyState();
          }

          _scheduleFlowResetIfNeeded(sublevels);

          if (!_isFlowStateValid(sublevels)) {
            return _buildLoadingState();
          }

          if (_showFinalResults) {
            return AssessmentFeedback.finalResult(
              correctCount: _totalCorrect,
              totalCount: _totalAnswered,
              categoryScores: sublevels
                  .map(
                    (sublevel) => CategoryScore(
                      label: sublevel.title,
                      displayLetter: sublevel.displayLetter,
                      correct: _sublevelScores[sublevel.id]?.correct ?? 0,
                      total: _sublevelScores[sublevel.id]?.total ?? 0,
                    ),
                  )
                  .toList(growable: false),
              onDone: () => Navigator.of(context).pop(),
            );
          }

          final currentSublevel = sublevels[_currentSublevelIndex];
          if (_showBreaker) {
            final score = _scoreFor(currentSublevel.id);
            return AssessmentFeedback.section(
              section: _currentSublevelIndex + 1,
              correctCount: score.correct,
              totalCount: score.total,
              categoryScores: [
                CategoryScore(
                  label: currentSublevel.title,
                  displayLetter: currentSublevel.displayLetter,
                  correct: score.correct,
                  total: score.total,
                ),
              ],
              isFinalSection: _currentSublevelIndex == sublevels.length - 1,
              onNext: () => _onBreakerNext(sublevels),
              onReview: () => _onBreakerReview(sublevels),
            );
          }

          final question = currentSublevel.questions[_currentQuestionIndex];
          final questionKey =
              '${widget.assessmentId}:${currentSublevel.id}:$_currentQuestionIndex';
          return Column(
            children: [
              _ProgressHeader(
                currentQuestion: _questionsCompletedSoFar(sublevels) + 1,
                totalQuestions: _totalQuestionCount(sublevels),
                sectionLabel: currentSublevel.title,
              ),
              Expanded(
                child: QuestionRenderer(
                  key: ValueKey(questionKey),
                  question: question,
                  questionKey: questionKey,
                  onAnswerChecked: (isCorrect) =>
                      _onAnswerChecked(isCorrect, sublevels),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.errorColor, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Failed to load assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(assessmentByIdProvider(widget.assessmentId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No assessment questions found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textColor,
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String sectionLabel;

  const _ProgressHeader({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.sectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalQuestions > 0 ? currentQuestion / totalQuestions : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sectionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentQuestion / $totalQuestions',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
