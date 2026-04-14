import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/shared/widgets/progress_widget.dart';
import 'package:milpress/utils/app_colors.dart';

enum _SoundCheckState {
  idle,
  correct,
  wrong,
}

class SoundCheckStep extends StatefulWidget {
  final String questionLabel;
  final int progressPercent;
  final int score;
  final int totalScore;
  final String question;
  final String audioUrl;
  final bool correctAnswer;
  final VoidCallback? onCorrect;
  final VoidCallback? onWrong;

  const SoundCheckStep({
    super.key,
    required this.questionLabel,
    required this.progressPercent,
    required this.score,
    required this.totalScore,
    required this.question,
    required this.audioUrl,
    required this.correctAnswer,
    this.onCorrect,
    this.onWrong,
  });

  @override
  State<SoundCheckStep> createState() => _SoundCheckStepState();
}

class _SoundCheckStepState extends State<SoundCheckStep> {
  _SoundCheckState _state = _SoundCheckState.idle;
  bool? _selectedAnswer;
  late int _displayScore;

  String get _questionLabel => widget.questionLabel.isNotEmpty
      ? widget.questionLabel
      : 'Question 1 of 5';

  int get _progressPercent => widget.progressPercent.clamp(0, 100);
  int get _totalScore => widget.totalScore <= 0 ? 1 : widget.totalScore;

  String get _question => widget.question.isNotEmpty
      ? widget.question
      : 'Does "man" have the /a/ sound?';

  String get _audioUrl => widget.audioUrl.isNotEmpty ? widget.audioUrl : '';

  @override
  void initState() {
    super.initState();
    _displayScore = widget.score < 0 ? 0 : widget.score;
  }

  void _handleAnswer(bool answer) {
    if (_selectedAnswer != null) return;
    final isCorrect = answer == widget.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _state = isCorrect ? _SoundCheckState.correct : _SoundCheckState.wrong;
      if (isCorrect) _displayScore += 1;
    });
    if (isCorrect) {
      widget.onCorrect?.call();
    } else {
      widget.onWrong?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Inner card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question label + score row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _questionLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    Text(
                      'Score: $_displayScore/$_totalScore',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ProgressWidget(
                  progress: _progressPercent / 100,
                  backgroundColor: AppColors.accentColor,
                  progressColor: AppColors.copBlue,
                  height: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 20),
                // Question text
                Text(
                  _question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Audio button — natural size, centered
                Center(
                  child: LessonAudioInlineButton(
                    sourceId: 'sound-check-audio',
                    url: _audioUrl,
                    backgroundColor: AppColors.copBlue,
                  ),
                ),
                const SizedBox(height: 10),
                // Chevron
                const Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_down,
                    size: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                // Yes / No buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildAnswerButton(
                        label: 'Yes',
                        answerValue: true,
                        fillColor: AppColors.successColor,
                        outlineColor: AppColors.successColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnswerButton(
                        label: 'No',
                        answerValue: false,
                        fillColor: AppColors.errorColor,
                        outlineColor: AppColors.errorColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool answerValue,
    required Color fillColor,
    required Color outlineColor,
  }) {
    final isSelected = _selectedAnswer == answerValue;
    final answered = _selectedAnswer != null;
    final shouldFill = answered && isSelected;

    Color bgColor = AppColors.backgroundColor;
    Color borderColor = outlineColor;
    Color textColor = outlineColor;

    if (shouldFill) {
      bgColor = fillColor;
      borderColor = fillColor;
      textColor = Colors.white;
    } else if (answered && !isSelected) {
      borderColor = AppColors.lightGrey;
      textColor = AppColors.textColor;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextButton(
        onPressed: answered ? null : () => _handleAnswer(answerValue),
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}