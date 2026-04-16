import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import 'model.dart';

class SoundItemMatchingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final VoidCallback onAdvanceRequested;

  const SoundItemMatchingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.onAdvanceRequested,
  });

  @override
  State<SoundItemMatchingStep> createState() => _SoundItemMatchingStepState();
}

class _SoundItemMatchingStepState extends State<SoundItemMatchingStep> {
  late final SoundItemMatchingConfig _config;
  int _currentActivityIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;

  SoundItemMatchingActivity get _currentActivity => _config.activities[
      _currentActivityIndex.clamp(0, _config.activities.length - 1)];

  SoundItemMatchingOption get _selectedOption =>
      _currentActivity.options[_selectedOptionIndex!];

  bool get _hasAnswered => _selectedOptionIndex != null;

  bool get _isCorrect => _hasAnswered && _selectedOption.isCorrect;

  bool get _isLastActivity =>
      _currentActivityIndex >= _config.activities.length - 1;

  @override
  void initState() {
    super.initState();
    _config = SoundItemMatchingConfig.fromMap(widget.step.config);
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

  void _handleOptionTap(int index) {
    if (_hasAnswered) {
      return;
    }

    final option = _currentActivity.options[index];
    setState(() {
      _selectedOptionIndex = index;
      if (option.isCorrect) {
        _score += 1;
      }
    });
    _publishUiState();
  }

  void _handleReview() {
    setState(() {
      _selectedOptionIndex = null;
    });
    _publishUiState();
  }

  void _handleContinue() {
    if (!_isCorrect) {
      _handleReview();
      return;
    }

    if (_isLastActivity) {
      widget.onAdvanceRequested();
      return;
    }

    setState(() {
      _currentActivityIndex += 1;
      _selectedOptionIndex = null;
    });
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    final activity = _currentActivity;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_config.title.isNotEmpty) ...[
            Text(
              _config.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: const Color(0xFFF5F3F0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Activity counter + score + progress bar
                  _MatchingHeader(
                    current: _currentActivityIndex + 1,
                    total: _config.activities.length,
                    score: _score,
                  ),
                  const SizedBox(height: 24),

                  // Prompt text centered
                  _PromptBlock(
                    prompt: activity.prompt,
                    targetSound: activity.targetSound,
                    promptAudioUrl: activity.promptAudioUrl,
                    sourceId:
                        '${widget.step.key}-prompt-$_currentActivityIndex',
                  ),
                  const SizedBox(height: 28),

                  // Audio play button centered
                  Center(
                    child: _SoundButton(
                      sourceId:
                          '${widget.step.key}-content-$_currentActivityIndex',
                      audioUrl: activity.contentAudioUrl,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Double chevron down arrow
                  const Center(
                    child: Icon(
                      Icons.keyboard_double_arrow_down_rounded,
                      color: Color(0xFF8A8A8A),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tip banner
                  _TipBanner(text: activity.tipText),
                  const SizedBox(height: 16),

                  // Option buttons row
                  Row(
                    children: [
                      for (var index = 0;
                          index < activity.options.length;
                          index++) ...[
                        Expanded(
                          child: _OptionButton(
                            label: activity.options[index].label,
                            state: _optionState(index),
                            onPressed: () => _handleOptionTap(index),
                          ),
                        ),
                        if (index < activity.options.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),

                  // Feedback bar (shown after answering)
                  if (_hasAnswered) ...[
                    const SizedBox(height: 14),
                    _FeedbackBar(
                      isCorrect: _isCorrect,
                      message: _isCorrect
                          ? '"${_selectedOption.label}" matches the ${activity.displayTargetSound} sound.'
                          : 'Try again and listen for the ${activity.displayTargetSound} sound.',
                      actionLabel: _isCorrect ? 'Continue' : 'Review',
                      onActionPressed:
                          _isCorrect ? _handleContinue : _handleReview,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _OptionVisualState _optionState(int index) {
    if (!_hasAnswered) {
      return _OptionVisualState.idle;
    }
    if (_selectedOptionIndex == index) {
      return _currentActivity.options[index].isCorrect
          ? _OptionVisualState.correct
          : _OptionVisualState.incorrect;
    }
    return _OptionVisualState.idle;
  }
}

class _MatchingHeader extends StatelessWidget {
  final int current;
  final int total;
  final int score;

  const _MatchingHeader({
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
              'Activity $safeCurrent of $safeTotal',
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
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: 8,
            backgroundColor: const Color(0xFFDDD8D1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.copBlue),
          ),
        ),
      ],
    );
  }
}

class _PromptBlock extends StatelessWidget {
  final String prompt;
  final String targetSound;
  final String promptAudioUrl;
  final String sourceId;

  const _PromptBlock({
    required this.prompt,
    required this.targetSound,
    required this.promptAudioUrl,
    required this.sourceId,
  });

  @override
  Widget build(BuildContext context) {
    final displayTargetSound = '/$targetSound/';
    final targetIndex = prompt.indexOf(displayTargetSound);
    const defaultStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Color(0xFF171B22),
      height: 1.3,
    );

    return Column(
      children: [
        if (targetIndex >= 0)
          Text.rich(
            TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(text: prompt.substring(0, targetIndex)),
                TextSpan(
                  text: displayTargetSound,
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
                TextSpan(
                  text:
                      prompt.substring(targetIndex + displayTargetSound.length),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          )
        else
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: defaultStyle,
          ),
        if (promptAudioUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          LessonAudioInlineButton(
            sourceId: sourceId,
            url: promptAudioUrl,
            backgroundColor: const Color(0xFFF8F8F8),
          ),
        ],
      ],
    );
  }
}

class _SoundButton extends StatelessWidget {
  final String sourceId;
  final String audioUrl;

  const _SoundButton({
    required this.sourceId,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return LessonAudioInlineButton(
      sourceId: sourceId,
      url: audioUrl,
      backgroundColor: AppColors.copBlue,
    );
  }
}

class _TipBanner extends StatelessWidget {
  final String text;

  const _TipBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9D0C7)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textColor,
          height: 1.3,
        ),
      ),
    );
  }
}

enum _OptionVisualState { idle, correct, incorrect }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionVisualState state;
  final VoidCallback onPressed;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (state) {
      _OptionVisualState.idle => Colors.white,
      _OptionVisualState.correct => AppColors.successColor,
      _OptionVisualState.incorrect => AppColors.errorColor,
    };
    final borderColor = switch (state) {
      _OptionVisualState.idle => const Color(0xFFD9D5CF),
      _OptionVisualState.correct => AppColors.successColor,
      _OptionVisualState.incorrect => AppColors.errorColor,
    };
    final textColor =
        state == _OptionVisualState.idle ? AppColors.textColor : Colors.white;

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: state == _OptionVisualState.idle ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor),
        ),
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
      padding: const EdgeInsets.all(10),
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
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: borderColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: borderColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}