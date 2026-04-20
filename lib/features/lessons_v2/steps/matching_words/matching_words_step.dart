import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: LessonStepCard(
        color: Colors.white,
        elevation: 3,
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonStepProgressHeader(
              current: _activityIndex + 1,
              total: _config.activities.length,
              itemLabel: 'Word',
              barColor: AppColors.copBlue,
              barBackgroundColor: const Color(0xFFDDD8D1),
            ),
            const SizedBox(height: 28),
            _PromptSection(
              stepKey: widget.step.key,
              activityIndex: _activityIndex,
              activity: activity,
              stepTitle: _config.title,
              instructionAudioUrl: _config.instructionAudioUrl,
            ),
            const SizedBox(height: 16),
            const LessonStepChevronDown(),
            const SizedBox(height: 16),
            _OptionsSection(
              activity: activity,
              selectedOptionId: _selectedOptionId,
              answered: _answered,
              onOptionTap: _handleOptionTap,
            ),
            if (_answered) ...[
              const SizedBox(height: 20),
              LessonFeedbackBar(
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PromptSection
// ---------------------------------------------------------------------------

class _PromptSection extends StatelessWidget {
  final String stepKey;
  final int activityIndex;
  final MatchingActivity activity;

  /// The step-level title (e.g. "Check Your Learning") shown as the bold heading.
  final String stepTitle;
  final String instructionAudioUrl;

  const _PromptSection({
    required this.stepKey,
    required this.activityIndex,
    required this.activity,
    required this.stepTitle,
    required this.instructionAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    final audioUrl = activity.promptAudioUrl.isNotEmpty
        ? activity.promptAudioUrl
        : instructionAudioUrl;

    return Column(
      children: [
        // Large orange circle audio button — matches screenshot
        if (audioUrl.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-activity-$activityIndex-prompt',
            url: audioUrl,
            backgroundColor: AppColors.primaryColor,
            iconColor: Colors.white,
            isCircular: true,
            defaultIcon: Icons.play_arrow_rounded,
          )
        else
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        const SizedBox(height: 14),
        // Bold large heading — step title e.g. "Check Your Learning"
        if (stepTitle.isNotEmpty)
          Text(
            stepTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
              height: 1.2,
            ),
          ),
        if (activity.promptText.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Smaller grey sub-prompt — e.g. 'Select "cat"'
          Text(
            activity.promptText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.textColor,
            ),
          ),
        ],
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

// ---------------------------------------------------------------------------
// _OptionsSection
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// _ImageOptionRow — evenly fills full row width, square image, label below
// ---------------------------------------------------------------------------

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final isSelected = selectedOptionId == opt.id;
        final isCorrect = opt.id == correctOptionId;

        Color borderColor = const Color(0xFFE8E0D8);
        double borderWidth = 1.5;

        if (isSelected && answered) {
          borderColor =
              isCorrect ? AppColors.successColor : AppColors.errorColor;
          borderWidth = 2.5;
        } else if (isSelected) {
          borderColor = AppColors.primaryColor;
          borderWidth = 2.5;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 5,
              right: i == options.length - 1 ? 0 : 5,
            ),
            child: GestureDetector(
              onTap: answered ? null : () => onOptionTap(opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square image area using AspectRatio so all cards are same height
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt.label,
                      textAlign: TextAlign.center,
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
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// _WordOptionRow
// ---------------------------------------------------------------------------

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

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: answered ? null : () => onOptionTap(opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
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
          ),
        );
      }).toList(),
    );
  }
}