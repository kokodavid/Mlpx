import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishUiState());
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
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = answer;
      if (_isCorrect) _score += 1;
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
    setState(() => _selectedAnswer = null);
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: LessonStepCard(
        color: const Color(0xFFF5F3F0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonStepProgressHeader(
              current: _currentQuestionIndex + 1,
              total: _config.questions.length,
              itemLabel: 'Question',
              score: _score,
              barColor: AppColors.copBlue,
              barBackgroundColor: const Color(0xFFDDD8D1),
            ),
            const SizedBox(height: 24),
            Text(
              question.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: LessonAudioInlineButton(
                sourceId:
                    '${widget.step.key}-question-$_currentQuestionIndex',
                url: question.promptAudioUrl,
                backgroundColor: AppColors.copBlue,
              ),
            ),
            const SizedBox(height: 16),
            const LessonStepChevronDown(color: Color(0xFF8A8A8A), size: 26),
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
            if (_selectedAnswer != null) ...[
              const SizedBox(height: 14),
              LessonFeedbackBar(
                isCorrect: _isCorrect,
                message: _isCorrect
                    ? '"${question.wordText}" matches ${question.displayTargetSound}.'
                    : '"${question.wordText}" does ${question.correctAnswer ? '' : 'not '}have ${question.displayTargetSound}.',
                actionLabel: _isCorrect ? 'Continue' : 'Review',
                onActionPressed: _isCorrect ? _handleContinue : _handleReview,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _PresenceButtonState _buttonState(bool answerValue) {
    if (_selectedAnswer == null) return _PresenceButtonState.idle;
    if (_selectedAnswer == answerValue) {
      return _isCorrect
          ? _PresenceButtonState.correct
          : _PresenceButtonState.incorrect;
    }
    return _PresenceButtonState.idle;
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
      _PresenceButtonState.idle => label.toLowerCase() == 'yes'
          ? AppColors.successColor
          : AppColors.errorColor,
      _PresenceButtonState.correct => AppColors.successColor,
      _PresenceButtonState.incorrect => AppColors.errorColor,
    };
    final backgroundColor = switch (state) {
      _PresenceButtonState.idle => label.toLowerCase() == 'yes'
          ? const Color(0xFFF2F8EE)
          : const Color(0xFFFFF1F0),
      _PresenceButtonState.correct => AppColors.successColor,
      _PresenceButtonState.incorrect => AppColors.errorColor,
    };
    final textColor = switch (state) {
      _PresenceButtonState.idle => borderColor,
      _PresenceButtonState.correct => Colors.white,
      _PresenceButtonState.incorrect => Colors.white,
    };

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: state == _PresenceButtonState.idle ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label, style: TextStyle(color: textColor)),
      ),
    );
  }
}