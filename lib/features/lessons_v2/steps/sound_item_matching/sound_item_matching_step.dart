import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
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

  void _handleOptionTap(int index) {
    if (_hasAnswered) return;
    final option = _currentActivity.options[index];
    setState(() {
      _selectedOptionIndex = index;
      if (option.isCorrect) _score += 1;
    });
    _publishUiState();
  }

  void _handleReview() {
    setState(() => _selectedOptionIndex = null);
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_config.title.isNotEmpty) ...[
            LessonStepTitle(title: _config.title),
            const SizedBox(height: 12),
          ],
          LessonStepCard(
            elevation: 2,
            borderRadius: 28,
            color: const Color(0xFFF6F6F6),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonStepProgressHeader(
                  current: _currentActivityIndex + 1,
                  total: _config.activities.length,
                  itemLabel: 'Activity',
                  score: _score,
                  barColor: AppColors.copBlue,
                  barBackgroundColor: const Color(0xFFF3E8DD),
                  barHeight: 10,
                ),
                const SizedBox(height: 20),
                _PromptBlock(
                  prompt: activity.prompt,
                  targetSound: activity.targetSound,
                  promptAudioUrl: activity.promptAudioUrl,
                  sourceId: '${widget.step.key}-prompt-$_currentActivityIndex',
                ),
                const SizedBox(height: 8),
                const LessonStepChevronDown(
                  color: Color(0xFF8A8A8A),
                  size: 24,
                ),
                const SizedBox(height: 8),
                LessonStepTipBanner(text: activity.tipText),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var index = 0;
                        index < activity.options.length;
                        index++) ...[
                      Expanded(
                        child: OptionButton(
                          label: activity.options[index].label,
                          variant: OptionButtonVariant.answerChip,
                          state: _optionState(index),
                          onTap: () => _handleOptionTap(index),
                        ),
                      ),
                      if (index < activity.options.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                if (_hasAnswered) ...[
                  const SizedBox(height: 12),
                  LessonFeedbackBar(
                    isCorrect: _isCorrect,
                    message: _isCorrect
                        ? '"${_selectedOption.label}" matches the ${activity.displayTargetSound} sound.'
                        : 'Try again and listen for the ${activity.displayTargetSound} sound.',
                    actionLabel: _isCorrect ? 'Continue' : 'Review',
                    onActionPressed: _isCorrect ? _handleContinue : _handleReview,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  OptionButtonState _optionState(int index) {
    if (!_hasAnswered) return OptionButtonState.idle;
    if (_selectedOptionIndex == index) {
      return _currentActivity.options[index].isCorrect
          ? OptionButtonState.correct
          : OptionButtonState.incorrect;
    }
    return OptionButtonState.idle;
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
    final vowel = targetSound.replaceAll('/', '');
    const defaultStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF171B22),
      height: 1.3,
    );

    final slashPattern = '/$vowel/';
    final slashIndex =
        prompt.toLowerCase().indexOf(slashPattern.toLowerCase());
    final targetIndex = slashIndex >= 0 ? slashIndex + 1 : -1;

    return Column(
      children: [
        if (promptAudioUrl.isNotEmpty) ...[
          Center(
            child: LessonAudioInlineButton(
              sourceId: sourceId,
              url: promptAudioUrl,
              isCircular: false,
              buttonSize: 48,
              backgroundColor: const Color(0xFF1B2A3B),
              iconColor: Colors.white,
              defaultIcon: Icons.volume_up_rounded,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (targetIndex >= 0)
          Text.rich(
            TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(text: prompt.substring(0, targetIndex)),
                TextSpan(
                  text: prompt.substring(targetIndex, targetIndex + vowel.length),
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
                TextSpan(text: prompt.substring(targetIndex + vowel.length)),
              ],
            ),
            textAlign: TextAlign.center,
          )
        else
          Text(prompt, textAlign: TextAlign.center, style: defaultStyle),
      ],
    );
  }
}