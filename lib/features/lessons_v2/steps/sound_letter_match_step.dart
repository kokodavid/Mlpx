import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/shared/widgets/progress_widget.dart';
import 'package:milpress/utils/app_colors.dart';

enum _SoundLetterMatchState {
  idle,
  correct,
  wrong,
}

class SoundLetterMatchStep extends StatefulWidget {
  final String activityLabel;
  final int progressPercent;
  final int score;
  final int totalScore;
  final String audioUrl;
  final String tipText;
  final List<String> options;
  final String correctOption;
  final VoidCallback? onCorrect;
  final VoidCallback? onWrong;

  const SoundLetterMatchStep({
    super.key,
    required this.activityLabel,
    required this.progressPercent,
    required this.score,
    required this.totalScore,
    required this.audioUrl,
    required this.tipText,
    required this.options,
    required this.correctOption,
    this.onCorrect,
    this.onWrong,
  });

  @override
  State<SoundLetterMatchStep> createState() => _SoundLetterMatchStepState();
}

class _SoundLetterMatchStepState extends State<SoundLetterMatchStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;
  _SoundLetterMatchState _state = _SoundLetterMatchState.idle;
  String? _selectedOption;

  String get _activityLabel => widget.activityLabel.isNotEmpty
      ? widget.activityLabel
      : 'Activity 1 of 5';

  int get _progressPercent => widget.progressPercent.clamp(0, 100);
  int get _score => widget.score < 0 ? 0 : widget.score;
  int get _totalScore => widget.totalScore <= 0 ? 1 : widget.totalScore;
  String get _audioUrl => widget.audioUrl.isNotEmpty ? widget.audioUrl : '';
  String get _tipText =>
      widget.tipText.isNotEmpty ? widget.tipText : 'Tip: Find the /a/ Sound';
  List<String> get _options =>
      widget.options.isNotEmpty ? widget.options : const ['cat', 'sit', 'pen'];
  String get _correctOption =>
      widget.correctOption.isNotEmpty ? widget.correctOption : 'cat';

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleOptionTap(String option) {
    if (_selectedOption != null) return;
    final isCorrect = option == _correctOption;
    setState(() {
      _selectedOption = option;
      _state = isCorrect
          ? _SoundLetterMatchState.correct
          : _SoundLetterMatchState.wrong;
    });
    if (isCorrect) {
      _sparkleController
        ..reset()
        ..forward();
      widget.onCorrect?.call();
    } else {
      widget.onWrong?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Scrollable body ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Activity label + score
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _activityLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor,
                          ),
                        ),
                      ),
                      Text(
                        'Score: $_score/$_totalScore',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ProgressWidget(
                    progress: _progressPercent / 100,
                    backgroundColor: AppColors.accentColor,
                    progressColor: AppColors.copBlue,
                    height: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 28),
                  // Instruction
                  _buildInstruction(),
                  const SizedBox(height: 28),
                  // Audio button
                  Center(
                    child: Container(
                      width: 92,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.copBlue,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.copBlue.withOpacity(0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: LessonAudioInlineButton(
                          sourceId: 'sound-letter-match-audio',
                          url: _audioUrl,
                          backgroundColor: AppColors.copBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        horizontal: 16, vertical: 12),
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
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Option buttons row
                  Row(
                    children: _options
                        .take(3)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isLast = index == (_options.take(3).length - 1);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 10),
                          child: _buildOptionButton(option),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Feedback card — only visible after a tap
                  if (_state != _SoundLetterMatchState.idle)
                    _buildFeedbackCard(),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 22,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColors.copBlue,
        ),
        children: [
          TextSpan(text: 'Tap the word that has\n'),
          TextSpan(text: 'the '),
          TextSpan(
            text: '/a/',
            style: TextStyle(color: AppColors.primaryColor),
          ),
          TextSpan(text: ' sound'),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    final isSelected = _selectedOption == option;
    final isCorrectSelected =
        _state == _SoundLetterMatchState.correct && isSelected;
    final isWrongSelected =
        _state == _SoundLetterMatchState.wrong && isSelected;

    Color backgroundColor = AppColors.backgroundColor;
    Color borderColor = AppColors.borderColor;
    Color textColor = AppColors.textColor;

    if (isCorrectSelected) {
      backgroundColor = AppColors.successColor;
      borderColor = AppColors.successColor;
      textColor = AppColors.backgroundColor;
    } else if (isWrongSelected) {
      backgroundColor = AppColors.errorColor;
      borderColor = AppColors.errorColor;
      textColor = AppColors.backgroundColor;
    }

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.copBlue.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        option,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );

    return GestureDetector(
      onTap: () => _handleOptionTap(option),
      child: isCorrectSelected
          ? _SparkleWrap(controller: _sparkleController, child: button)
          : button,
    );
  }

  /// Feedback card shown below the options after the user taps.
  Widget _buildFeedbackCard() {
    final isCorrect = _state == _SoundLetterMatchState.correct;

    final borderColor = isCorrect
        ? AppColors.successColor.withOpacity(0.45)
        : AppColors.errorColor.withOpacity(0.35);
    final bgColor = isCorrect
        ? AppColors.successColor.withOpacity(0.08)
        : AppColors.errorLightShade;
    final accentColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final iconData = isCorrect ? Icons.check_circle_outline : Icons.close;
    final headerText = isCorrect ? 'Excellent!' : 'Try Again!';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: isCorrect
          ? _buildCorrectFeedbackContent(accentColor, iconData, headerText)
          : _buildWrongFeedbackContent(accentColor, iconData, headerText),
    );
  }

  /// Correct: icon + bold header, word phoneme breakdown, explanation line.
  Widget _buildCorrectFeedbackContent(
      Color color, IconData icon, String header) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_correctOption - /a/ - $_correctOption',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'The a in $_correctOption makes the /a/ sound.',
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Wrong: icon + bold header, short hint line.
  Widget _buildWrongFeedbackContent(
      Color color, IconData icon, String header) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Listen again for /a/ like in 'apple'.",
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparkleWrap extends StatelessWidget {
  final Widget child;
  final Animation<double> controller;

  const _SparkleWrap({required this.child, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final opacity = (1 - controller.value).clamp(0.0, 1.0);
        final scale = 0.92 + (controller.value * 0.18);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(scale: scale, child: child),
            ..._sparkles(opacity),
          ],
        );
      },
    );
  }

  List<Widget> _sparkles(double opacity) {
    const positions = <Offset>[
      Offset(-42, -20),
      Offset(-24, -30),
      Offset(0, -34),
      Offset(26, -28),
      Offset(44, -16),
      Offset(-38, 10),
      Offset(38, 12),
    ];
    return positions
        .map((offset) => Positioned(
              left: 50 + offset.dx,
              top: 18 + offset.dy,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: AppColors.successColor.withOpacity(
                    0.35 + (opacity * 0.65),
                  ),
                ),
              ),
            ))
        .toList();
  }
}