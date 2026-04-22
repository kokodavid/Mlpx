import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';

class _RuntimeSlot {
  final AnswerSlotDefinition definition;
  String? filledValue;
  int? selectedOptionIndex;

  _RuntimeSlot(this.definition)
      : filledValue = definition.isGiven ? definition.value : null,
        selectedOptionIndex = null;

  bool get isFilled => filledValue != null;
}

class MissingLettersStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MissingLettersStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MissingLettersStep> createState() => _MissingLettersStepState();
}

class _MissingLettersStepState extends State<MissingLettersStep> {
  late final MissingLettersConfig _config;

  int _activityIndex = 0;
  late List<_RuntimeSlot> _slots;
  late List<String> _options;
  final Set<int> _usedOptionIndices = {};
  _CheckResult _result = _CheckResult.none;

  MissingLettersActivity get _activity => _config
      .activities[_activityIndex.clamp(0, _config.activities.length - 1)];

  bool get _isLastActivity => _activityIndex >= _config.activities.length - 1;

  int? get _nextEmptySlotIndex {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i].definition.isMissing && !_slots[i].isFilled) return i;
    }
    return null;
  }

  bool get _allMissingFilled => _nextEmptySlotIndex == null;

  bool get _isAnswerCorrect =>
      _slots.every((s) => s.filledValue == s.definition.value);

  @override
  void initState() {
    super.initState();
    _config = MissingLettersConfig.fromMap(widget.step.config);
    _loadActivity(_activityIndex);
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

  void _loadActivity(int index) {
    _usedOptionIndices.clear();
    _result = _CheckResult.none;
    _slots = _activity.answerTemplate.map((def) => _RuntimeSlot(def)).toList();
    _options = List<String>.from(_activity.options);
  }

  void _handleOptionTap(int optionIndex) {
    if (_result != _CheckResult.none) return;

    final isAlreadyUsed = _usedOptionIndices.contains(optionIndex);
    if (isAlreadyUsed) {
      final slotIndex = _slots.indexWhere(
        (slot) => slot.selectedOptionIndex == optionIndex,
      );
      if (slotIndex >= 0) {
        setState(() {
          _slots[slotIndex].filledValue = null;
          _slots[slotIndex].selectedOptionIndex = null;
          _usedOptionIndices.remove(optionIndex);
        });
      }
      return;
    }

    final emptyIdx = _nextEmptySlotIndex;
    if (emptyIdx == null) return;

    setState(() {
      _slots[emptyIdx].filledValue = _options[optionIndex];
      _slots[emptyIdx].selectedOptionIndex = optionIndex;
      _usedOptionIndices.add(optionIndex);
    });
  }

  void _handleCheckWord() {
    if (!_allMissingFilled) return;
    setState(() {
      _result =
          _isAnswerCorrect ? _CheckResult.correct : _CheckResult.incorrect;
    });
    _publishUiState();
  }

  void _handleTryAgain() {
    setState(() {
      _loadActivity(_activityIndex);
    });
    _publishUiState();
  }

  void _handleContinue() {
    if (_isLastActivity) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _activityIndex += 1;
      _loadActivity(_activityIndex);
    });
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    if (_config.activities.isEmpty) {
      return const Center(child: Text('No activities configured.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_config.title.isNotEmpty) ...[
            Text(
              _config.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
          ],
          LessonStepCard(
            color: const Color(0xFFF6F6F6),
            elevation: 3,
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonStepProgressHeader(
                  current: _activityIndex + 1,
                  total: _config.activities.length,
                  itemLabel: 'Word',
                  barColor: AppColors.copBlue,
                  barHeight: 8,
                  barBackgroundColor: const Color(0xFFDDD8D1),
                ),
                const SizedBox(height: 20),
                _InstructionSection(
                  stepKey: widget.step.key,
                  instructionText: _config.instructionText,
                  promptText: _activity.promptText,
                  instructionAudioUrl: _config.instructionAudioUrl,
                ),
                const SizedBox(height: 20),
                _SlotRow(slots: _slots, result: _result),
                const SizedBox(height: 12),
                const LessonStepChevronDown(
                  color: Color(0xFF8A8A8A),
                  size: 26,
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Selects missing letter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF142C44),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _OptionGrid(
                  options: _options,
                  usedIndices: _usedOptionIndices,
                  locked: _result != _CheckResult.none,
                  onTap: _handleOptionTap,
                ),
                const SizedBox(height: 14),
                _buildBottomAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    switch (_result) {
      case _CheckResult.none:
        if (!_allMissingFilled) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleCheckWord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Check Word',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case _CheckResult.incorrect:
        return LessonFeedbackBar(
          isCorrect: false,
          message: 'That\'s not quite right. Try again!',
          actionLabel: 'Try Again',
          onActionPressed: _handleTryAgain,
        );

      case _CheckResult.correct:
        return LessonFeedbackBar(
          isCorrect: true,
          message: '"${_activity.targetWord}" — Well done!',
          actionLabel: _isLastActivity ? 'Finish' : 'Continue',
          onActionPressed: _handleContinue,
        );
    }
  }
}

class _InstructionSection extends StatelessWidget {
  final String stepKey;
  final String instructionText;
  final String promptText;
  final String? instructionAudioUrl;

  const _InstructionSection({
    required this.stepKey,
    required this.instructionText,
    required this.promptText,
    this.instructionAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LessonAudioInlineButton(
          sourceId: '$stepKey-instruction',
          url: instructionAudioUrl ?? '',
          isCircular: true,
          buttonSize: 44,
          backgroundColor: AppColors.primaryColor,
          iconColor: Colors.white,
          defaultIcon: Icons.play_arrow,
        ),
        const SizedBox(height: 10),
        if (instructionText.isNotEmpty) ...[
          Text(
            instructionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          'Make "$promptText"',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textColor,
          ),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  final List<_RuntimeSlot> slots;
  final _CheckResult result;

  const _SlotRow({required this.slots, required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(slots.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _SlotTile(slot: slots[i], result: result),
        );
      }),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final _RuntimeSlot slot;
  final _CheckResult result;

  const _SlotTile({required this.slot, required this.result});

  @override
  Widget build(BuildContext context) {
    const double size = 52;

    if (slot.definition.isGiven) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          slot.definition.value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    final filled = slot.isFilled;

    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (!filled) {
      borderColor = AppColors.primaryColor.withOpacity(0.5);
      bgColor = Colors.white;
      textColor = AppColors.primaryColor;
    } else if (result == _CheckResult.incorrect) {
      borderColor = AppColors.errorColor;
      bgColor = const Color(0xFFFFF0F0);
      textColor = AppColors.errorColor;
    } else {
      borderColor = AppColors.primaryColor.withOpacity(0.7);
      bgColor = const Color(0xFFFAEDE6);
      textColor = AppColors.primaryColor;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: filled
          ? Text(
              slot.filledValue!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            )
          : Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  final List<String> options;
  final Set<int> usedIndices;
  final bool locked;
  final ValueChanged<int> onTap;

  const _OptionGrid({
    required this.options,
    required this.usedIndices,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < options.length; i += 3) {
      final end = (i + 3).clamp(0, options.length);
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(end - i, (j) {
            final idx = i + j;
            return Padding(
              padding: const EdgeInsets.all(4),
              child: _OptionButton(
                letter: options[idx],
                used: usedIndices.contains(idx),
                locked: locked,
                onTap: () => onTap(idx),
              ),
            );
          }),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _OptionButton extends StatelessWidget {
  final String letter;
  final bool used;
  final bool locked;
  final VoidCallback onTap;

  const _OptionButton({
    required this.letter,
    required this.used,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLight = Color(0xFFFAEDE6);

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80,
        height: 44,
        decoration: BoxDecoration(
          color: used ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: used ? AppColors.primaryColor : AppColors.borderColor,
            width: used ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: used ? AppColors.primaryColor : AppColors.textColor,
          ),
        ),
      ),
    );
  }
}

enum _CheckResult { none, correct, incorrect }