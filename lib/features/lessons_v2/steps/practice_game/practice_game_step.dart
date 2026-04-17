import 'dart:async';

import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import 'model.dart';

class PracticeGameStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final VoidCallback onAdvanceRequested;

  const PracticeGameStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.onAdvanceRequested,
  });

  @override
  State<PracticeGameStep> createState() => _PracticeGameStepState();
}

class _PracticeGameStepState extends State<PracticeGameStep> {
  late final PracticeGameConfig _config;
  final Set<int> _selected = <int>{};
  Timer? _timer;
  late int _secondsRemaining;
  bool _isFinished = false;

  int get _score =>
      _selected.where((i) => _config.options[i].isCorrect).length;

  bool get _passed => _score >= _config.passingScore;

  int get _correctOptionCount =>
      _config.options.where((option) => option.isCorrect).length;

  @override
  void initState() {
    super.initState();
    _config = PracticeGameConfig.fromMap(widget.step.config);
    _secondsRemaining = _config.durationSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishUiState();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _startTimer() {
    _timer?.cancel();
    if (_config.durationSeconds <= 0) {
      _finishGame();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        _finishGame();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  void _finishGame() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _isFinished = true);
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _selected.clear();
      _secondsRemaining = _config.durationSeconds;
      _isFinished = false;
    });
    _publishUiState();
    _startTimer();
  }

  void _handleOptionTap(int index) {
    if (_isFinished) return;
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    if (_score >= _correctOptionCount) {
      _finishGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _config.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171B22),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF2ECE4)),
            ),
            child: Column(
              children: [
                LessonAudioInlineButton(
                  sourceId: '${widget.step.key}-instruction',
                  url: _config.instructionAudioUrl,
                  backgroundColor: AppColors.primaryColor,
                  iconColor: Colors.white,
                  isCircular: true,
                  defaultIcon: Icons.play_arrow,
                ),
                const SizedBox(height: 18),
                _HighlightedInstruction(
                  title: _config.title,
                  instructionText: _config.instructionText,
                  targetSound: _config.targetSound,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.timer_outlined,
                        text: 'Time: ${_secondsRemaining}s',
                        textColor: AppColors.copBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        text: 'Score: $_score',
                        textColor: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _config.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.73,
            ),
            itemBuilder: (context, index) {
              final option = _config.options[index];
              final state = _cardState(index);
              return _GameOptionCard(
                option: option,
                state: state,
                sourceId: '${widget.step.key}-option-$index',
                onTap: () => _handleOptionTap(index),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_isFinished)
            LessonFeedbackBar(
              isCorrect: _passed,
              message: _passed
                  ? 'Score $_score. You passed this game.'
                  : 'Score $_score. Reach ${_config.passingScore} to pass.',
              actionLabel: _passed ? 'Continue' : 'Review',
              onActionPressed:
                  _passed ? widget.onAdvanceRequested : _resetGame,
            ),
        ],
      ),
    );
  }

  _GameCardState _cardState(int index) {
    if (!_selected.contains(index)) return _GameCardState.idle;
    return _config.options[index].isCorrect
        ? _GameCardState.correct
        : _GameCardState.incorrect;
  }
}



class _HighlightedInstruction extends StatelessWidget {
  final String title;
  final String instructionText;
  final String targetSound;

  const _HighlightedInstruction({
    required this.title,
    required this.instructionText,
    required this.targetSound,
  });

  @override
  Widget build(BuildContext context) {
    final displayTargetSound = '/$targetSound/';
    final titleIndex = title.indexOf(displayTargetSound);

    Widget buildRich(String text, int matchIndex, TextStyle baseStyle) {
      return Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: text.substring(0, matchIndex)),
            TextSpan(
              text: displayTargetSound,
              style: const TextStyle(color: AppColors.primaryColor),
            ),
            TextSpan(
                text: text.substring(matchIndex + displayTargetSound.length)),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }

    const titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: Color(0xFF171B22),
      height: 1.2,
    );
    const instructionStyle = TextStyle(
      fontSize: 17,
      color: AppColors.textColor,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );
    final instructionIndex = instructionText.indexOf(displayTargetSound);

    return Column(
      children: [
        titleIndex >= 0
            ? buildRich(title, titleIndex, titleStyle)
            : Text(title, textAlign: TextAlign.center, style: titleStyle),
        const SizedBox(height: 10),
        instructionIndex >= 0
            ? buildRich(instructionText, instructionIndex, instructionStyle)
            : Text(
                instructionText,
                textAlign: TextAlign.center,
                style: instructionStyle,
              ),
      ],
    );
  }
}



class _StatChip extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color textColor;

  const _StatChip({
    this.icon,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DDD0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}


enum _GameCardState { idle, correct, incorrect }

class _GameOptionCard extends StatelessWidget {
  final PracticeGameOption option;
  final _GameCardState state;
  final String sourceId;
  final VoidCallback onTap;

  const _GameOptionCard({
    required this.option,
    required this.state,
    required this.sourceId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (state) {
      _GameCardState.idle => const Color(0xFFE7DDD0),
      _GameCardState.correct => AppColors.successColor,
      _GameCardState.incorrect => AppColors.errorColor,
    };
    final backgroundColor = switch (state) {
      _GameCardState.idle => Colors.white,
      _GameCardState.correct => const Color(0xFFF2F8EE),
      _GameCardState.incorrect => const Color(0xFFFFF1F0),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF7F7F7),
                  child: option.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.textColor,
                            size: 32,
                          ),
                        )
                      : Image.network(
                          option.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textColor,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 2),
            IgnorePointer(
              child: LessonAudioInlineButton(
                sourceId: sourceId,
                url: option.audioUrl,
                backgroundColor: const Color(0xFFF8F8F8),
                buttonSize: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}