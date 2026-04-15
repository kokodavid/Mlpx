import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';



class MatchingWordsStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MatchingWordsStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MatchingWordsStep> createState() => _MatchingWordsStepState();
}

class _MatchingWordsStepState extends State<MatchingWordsStep> {
  late final MatchingWordsConfig _config;

  int _activityIndex = 0;
  String? _selectedOptionId;
  bool _answered = false;

  

  MatchingActivity get _activity =>
      _config.activities[
          _activityIndex.clamp(0, _config.activities.length - 1)];

  bool get _isLastActivity => _activityIndex >= _config.activities.length - 1;

  bool get _isCorrect =>
      _selectedOptionId != null &&
      _selectedOptionId == _activity.correctOptionId;


  @override
  void initState() {
    super.initState();
    _config = MatchingWordsConfig.fromMap(widget.step.config);
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

  

  void _handleOptionTap(String optionId) {
    if (_answered) return;
    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
    });
    _publishUiState();
  }

  void _handleContinue() {
    if (!_isCorrect) {
      // Wrong: clear selection, let them try again.
      setState(() {
        _selectedOptionId = null;
        _answered = false;
      });
      _publishUiState();
      return;
    }

    if (_isLastActivity) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }

    setState(() {
      _activityIndex += 1;
      _selectedOptionId = null;
      _answered = false;
    });
    _publishUiState();
  }


  @override
  Widget build(BuildContext context) {
    if (_config.activities.isEmpty) {
      return const Center(child: Text('No activities configured.'));
    }

    final activity = _activity;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  current: _activityIndex + 1,
                  total: _config.activities.length,
                ),
                const SizedBox(height: 28),
                _PromptSection(
                  stepKey: widget.step.key,
                  activityIndex: _activityIndex,
                  activity: activity,
                  instructionAudioUrl: _config.instructionAudioUrl,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: AppColors.textColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                _OptionsSection(
                  activity: activity,
                  selectedOptionId: _selectedOptionId,
                  answered: _answered,
                  onOptionTap: _handleOptionTap,
                ),
                const SizedBox(height: 20),
                if (_answered)
                  _FeedbackBar(
                    isCorrect: _isCorrect,
                    message: _isCorrect
                        ? '"${_activity.options.firstWhere((o) => o.id == _selectedOptionId, orElse: () => const MatchingOption(id: '', label: '', imageUrl: '')).label}" — Well done!'
                        : 'Not quite. Try again!',
                    actionLabel: _isCorrect
                        ? (_isLastActivity ? 'Finish' : 'Continue')
                        : 'Try Again',
                    onActionPressed: _handleContinue,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}



class _Header extends StatelessWidget {
  final int current;
  final int total;

  const _Header({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word $safeCurrent of $safeTotal',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: 10,
            backgroundColor: const Color(0xFFF3E8DD),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.copBlue),
          ),
        ),
      ],
    );
  }
}



class _PromptSection extends StatelessWidget {
  final String stepKey;
  final int activityIndex;
  final MatchingActivity activity;
  final String instructionAudioUrl;

  const _PromptSection({
    required this.stepKey,
    required this.activityIndex,
    required this.activity,
    required this.instructionAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Audio button: prefer activity-level audio, fall back to instruction audio.
    final audioUrl = activity.promptAudioUrl.isNotEmpty
        ? activity.promptAudioUrl
        : instructionAudioUrl;

    return Column(
      children: [
        if (audioUrl.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-activity-$activityIndex-prompt',
            url: audioUrl,
            backgroundColor: AppColors.primaryColor,
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.play_arrow, color: Colors.white, size: 26),
          ),
        const SizedBox(height: 14),
        Text(
          activity.promptText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF171B22),
          ),
        ),
        // image_to_word: show prompt image below title.
        if (activity.mode == MatchingMode.imageToWord &&
            activity.promptImageUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PromptImage(imageUrl: activity.promptImageUrl),
        ],
      ],
    );
  }
}

class _PromptImage extends StatelessWidget {
  final String imageUrl;

  const _PromptImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0EBE4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.textColor,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _OptionsSection extends StatelessWidget {
  final MatchingActivity activity;
  final String? selectedOptionId;
  final bool answered;
  final ValueChanged<String> onOptionTap;

  const _OptionsSection({
    required this.activity,
    required this.selectedOptionId,
    required this.answered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (activity.mode) {
      MatchingMode.soundToImage => _ImageOptionRow(
          options: activity.options,
          selectedOptionId: selectedOptionId,
          correctOptionId: activity.correctOptionId,
          answered: answered,
          onOptionTap: onOptionTap,
        ),
      MatchingMode.soundToWord || MatchingMode.imageToWord => _WordOptionRow(
          options: activity.options,
          selectedOptionId: selectedOptionId,
          correctOptionId: activity.correctOptionId,
          answered: answered,
          onOptionTap: onOptionTap,
        ),
    };
  }
}



class _ImageOptionRow extends StatelessWidget {
  final List<MatchingOption> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool answered;
  final ValueChanged<String> onOptionTap;

  const _ImageOptionRow({
    required this.options,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.answered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((opt) {
        final isSelected = selectedOptionId == opt.id;
        final isCorrect = opt.id == correctOptionId;

        Color borderColor = const Color(0xFFF0EBE4);
        double borderWidth = 1.5;

        if (isSelected && answered) {
          borderColor = isCorrect ? AppColors.successColor : AppColors.errorColor;
          borderWidth = 2.5;
        } else if (isSelected) {
          borderColor = AppColors.primaryColor;
          borderWidth = 2.5;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: answered ? null : () => onOptionTap(opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                children: [
                  SizedBox(
                    height: 72,
                    child: opt.imageUrl.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textColor,
                              size: 36,
                            ),
                          )
                        : Image.network(
                            opt.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textColor,
                                size: 36,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (answered
                              ? (isCorrect
                                  ? AppColors.successColor
                                  : AppColors.errorColor)
                              : AppColors.primaryColor)
                          : AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}



class _WordOptionRow extends StatelessWidget {
  final List<MatchingOption> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool answered;
  final ValueChanged<String> onOptionTap;

  const _WordOptionRow({
    required this.options,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.answered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((opt) {
        final isSelected = selectedOptionId == opt.id;
        final isCorrect = opt.id == correctOptionId;

        Color borderColor = const Color(0xFFD9D0C7);
        Color bgColor = Colors.white;
        Color textColor = AppColors.textColor;
        double borderWidth = 1.5;

        if (isSelected && answered) {
          borderColor =
              isCorrect ? AppColors.successColor : AppColors.errorColor;
          bgColor = isCorrect
              ? AppColors.successColor.withOpacity(0.06)
              : AppColors.errorColor.withOpacity(0.06);
          textColor =
              isCorrect ? AppColors.successColor : AppColors.errorColor;
          borderWidth = 2;
        } else if (isSelected) {
          borderColor = AppColors.primaryColor;
          bgColor = AppColors.primaryColor.withOpacity(0.06);
          textColor = AppColors.primaryColor;
          borderWidth = 2;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: answered ? null : () => onOptionTap(opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              constraints: const BoxConstraints(minWidth: 88),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              alignment: Alignment.center,
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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