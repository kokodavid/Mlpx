import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import 'model.dart';

class SoundPresenceCheckStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final VoidCallback onAdvanceRequested;

  const SoundPresenceCheckStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.onAdvanceRequested,
  });

  @override
  State<SoundPresenceCheckStep> createState() => _SoundPresenceCheckStepState();
}

class _SoundPresenceCheckStepState extends State<SoundPresenceCheckStep> {
  late final SoundPresenceCheckConfig _config;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool? _selectedAnswer;

  SoundPresenceQuestion get _question => _config
      .questions[_currentQuestionIndex.clamp(0, _config.questions.length - 1)];

  bool get _isCorrect =>
      _selectedAnswer != null && _selectedAnswer == _question.correctAnswer;

  bool get _isLastQuestion =>
      _currentQuestionIndex >= _config.questions.length - 1;

  @override
  void initState() {
    super.initState();
    _config = SoundPresenceCheckConfig.fromMap(widget.step.config);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishUiState();
    });
  }

  void _publishUiState() {
    widget.onStepStateChanged(
      const LessonStepUiState(
        canAdvance: false,
        isPrimaryEnabled: false,
        showBottomActionBar: false,
      ),
    );
  }

  void _handleAnswer(bool answer) {
    if (_selectedAnswer != null) {
      return;
    }

    setState(() {
      _selectedAnswer = answer;
      if (_isCorrect) {
        _score += 1;
      }
    });
    _publishUiState();
  }

  void _handleContinue() {
    if (_isLastQuestion) {
      widget.onAdvanceRequested();
      return;
    }
    setState(() {
      _currentQuestionIndex += 1;
      _selectedAnswer = null;
    });
    _publishUiState();
  }

  void _handleReview() {
    setState(() {
      _selectedAnswer = null;
    });
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  current: _currentQuestionIndex + 1,
                  total: _config.questions.length,
                  score: _score,
                ),
                const SizedBox(height: 20),
                Text(
                  question.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B22),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: LessonAudioInlineButton(
                    sourceId:
                        '${widget.step.key}-question-$_currentQuestionIndex',
                    url: question.promptAudioUrl,
                    backgroundColor: AppColors.copBlue,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: AppColors.copBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                _WordCard(
                  stepKey: widget.step.key,
                  questionIndex: _currentQuestionIndex,
                  wordText: question.wordText,
                  wordAudioUrl: question.wordAudioUrl,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AnswerButton(
                        label: question.yesLabel,
                        state: _buttonState(true),
                        onPressed: () => _handleAnswer(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnswerButton(
                        label: question.noLabel,
                        state: _buttonState(false),
                        onPressed: () => _handleAnswer(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_selectedAnswer != null)
                  _FeedbackBar(
                    isCorrect: _isCorrect,
                    message: _isCorrect
                        ? '"${question.wordText}" matches ${question.displayTargetSound}.'
                        : '"${question.wordText}" does ${question.correctAnswer ? '' : 'not '}have ${question.displayTargetSound}.',
                    actionLabel: _isCorrect ? 'Continue' : 'Review',
                    onActionPressed:
                        _isCorrect ? _handleContinue : _handleReview,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  _PresenceButtonState _buttonState(bool answerValue) {
    if (_selectedAnswer == null) {
      return _PresenceButtonState.idle;
    }
    if (_selectedAnswer == answerValue) {
      return _isCorrect
          ? _PresenceButtonState.correct
          : _PresenceButtonState.incorrect;
    }
    return _PresenceButtonState.idle;
  }
}

class _Header extends StatelessWidget {
  final int current;
  final int total;
  final int score;

  const _Header({
    required this.current,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question $safeCurrent of $safeTotal',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Score: $score/$safeTotal',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: 10,
            backgroundColor: const Color(0xFFF3E8DD),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.copBlue),
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final String stepKey;
  final int questionIndex;
  final String wordText;
  final String wordAudioUrl;

  const _WordCard({
    required this.stepKey,
    required this.questionIndex,
    required this.wordText,
    required this.wordAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF2ECE4)),
        ),
        child: Column(
          children: [
            Text(
              wordText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
            LessonAudioInlineButton(
              sourceId: '$stepKey-word-$questionIndex',
              url: wordAudioUrl,
              backgroundColor: const Color(0xFFF8F8F8),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PresenceButtonState { idle, correct, incorrect }

class _AnswerButton extends StatelessWidget {
  final String label;
  final _PresenceButtonState state;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (state) {
      _PresenceButtonState.idle => const Color(0xFFE7DDD0),
      _PresenceButtonState.correct => AppColors.successColor,
      _PresenceButtonState.incorrect => AppColors.errorColor,
    };
    final backgroundColor = switch (state) {
      _PresenceButtonState.idle => Colors.white,
      _PresenceButtonState.correct => AppColors.successColor,
      _PresenceButtonState.incorrect => AppColors.errorColor,
    };
    final textColor =
        state == _PresenceButtonState.idle ? AppColors.textColor : Colors.white;

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: state == _PresenceButtonState.idle ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _FeedbackBar({
    required this.isCorrect,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final backgroundColor =
        isCorrect ? const Color(0xFFF2F8EE) : const Color(0xFFFFF1F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: borderColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: borderColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
