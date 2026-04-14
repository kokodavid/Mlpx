import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/shared/widgets/progress_widget.dart';
import 'package:milpress/utils/app_colors.dart';

enum _SoundDiscriminationViewState {
  defaultState,
  correct,
  wrong,
}

class SoundDiscriminationStep extends StatefulWidget {
  final String question;
  final String imageUrl;
  final String word;
  final String audioUrl;
  final String tipText;
  final String activityLabel;
  final int progressPercent;
  final bool correctAnswer;
  final VoidCallback? onCorrect;
  final VoidCallback? onWrong;

  const SoundDiscriminationStep({
    super.key,
    required this.question,
    required this.imageUrl,
    required this.word,
    required this.audioUrl,
    required this.tipText,
    required this.activityLabel,
    required this.progressPercent,
    required this.correctAnswer,
    this.onCorrect,
    this.onWrong,
  });

  @override
  State<SoundDiscriminationStep> createState() =>
      _SoundDiscriminationStepState();
}

class _SoundDiscriminationStepState extends State<SoundDiscriminationStep> {
  _SoundDiscriminationViewState _viewState =
      _SoundDiscriminationViewState.defaultState;

  String get _question =>
      widget.question.isNotEmpty ? widget.question : 'Does it have /a/?';

  String get _imageUrl => widget.imageUrl;

  String get _word => widget.word.isNotEmpty ? widget.word : 'cat';

  String get _audioUrl => widget.audioUrl.isNotEmpty ? widget.audioUrl : '';

  String get _tipText => widget.tipText.isNotEmpty
      ? widget.tipText
      : "Tip: Listen to the word. Does it have the /a/ sound, like in 'apple'?";

  String get _activityLabel => widget.activityLabel.isNotEmpty
      ? widget.activityLabel
      : 'Activity 1 of 5';

  int get _progressPercent => widget.progressPercent.clamp(0, 100);

  String get _targetSound {
    final match = RegExp(r'/[^/]+/').firstMatch(_question);
    return match?.group(0) ?? '/a/';
  }

  String get _correctFeedback => "Yes! '$_word' has the $_targetSound sound.";

  String get _wrongFeedback =>
      "Listen again for $_targetSound like in 'apple'.";

  void _handleAnswer(bool selectedAnswer) {
    final isCorrect = selectedAnswer == widget.correctAnswer;
    setState(() {
      _viewState = isCorrect
          ? _SoundDiscriminationViewState.correct
          : _SoundDiscriminationViewState.wrong;
    });

    if (isCorrect) {
      widget.onCorrect?.call();
    } else {
      widget.onWrong?.call();
    }
  }

  void _handleReview() {
    setState(() {
      _viewState = _SoundDiscriminationViewState.defaultState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      // Use a Column so the scrollable body + fixed bottom don't fight each other
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Scrollable body ──────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Activity label
                  Text(
                    _activityLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ProgressWidget(
                    progress: _progressPercent / 100,
                    backgroundColor: AppColors.accentColor,
                    progressColor: AppColors.copBlue,
                    height: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 24),
                  // Question
                  Text(
                    _question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.copBlue,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Image card
                  Center(
                    child: Container(
                      width: 184,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.copBlue.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 160,
                              height: 160,
                              color: AppColors.whiteSmoke,
                              child: _imageUrl.isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 44,
                                        color: AppColors.textColor,
                                      ),
                                    )
                                  : Image.network(
                                      _imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 44,
                                            color: AppColors.textColor,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _word,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.copBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LessonAudioInlineButton(
                            sourceId: 'sound-discrimination-$_word',
                            url: _audioUrl,
                            backgroundColor: AppColors.whiteSmoke,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Chevron
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.expand_more,
                      size: 34,
                      color: AppColors.copBlue,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tip box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Text(
                      _tipText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action area ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildBottomState(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomState() {
    switch (_viewState) {
      case _SoundDiscriminationViewState.correct:
        return _buildFeedbackRow(
          borderColor: AppColors.successColor.withOpacity(0.5),
          backgroundColor: AppColors.successColor.withOpacity(0.08),
          icon: Icons.check,
          iconColor: AppColors.successColor,
          message: _correctFeedback,
          messageColor: AppColors.successColor,
          actionLabel: 'Continue',
          actionColor: AppColors.primaryColor,
          onPressed: () {},
        );
      case _SoundDiscriminationViewState.wrong:
        return _buildFeedbackRow(
          borderColor: AppColors.errorColor.withOpacity(0.45),
          backgroundColor: AppColors.errorLightShade,
          icon: Icons.close,
          iconColor: AppColors.errorColor,
          message: _wrongFeedback,
          messageColor: AppColors.errorColor,
          actionLabel: 'Review',
          actionColor: AppColors.errorColor,
          onPressed: _handleReview,
        );
      case _SoundDiscriminationViewState.defaultState:
        return Row(
          children: [
            Expanded(
              child: _buildAnswerButton(
                label: 'Yes, $_targetSound',
                borderColor: AppColors.successColor.withOpacity(0.5),
                textColor: AppColors.successColor,
                onPressed: () => _handleAnswer(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnswerButton(
                label: 'No, Not $_targetSound',
                borderColor: AppColors.errorColor.withOpacity(0.5),
                textColor: AppColors.errorColor,
                onPressed: () => _handleAnswer(false),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAnswerButton({
    required String label,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackRow({
    required Color borderColor,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required String message,
    required Color messageColor,
    required String actionLabel,
    required Color actionColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: messageColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: actionColor,
                foregroundColor: AppColors.backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}