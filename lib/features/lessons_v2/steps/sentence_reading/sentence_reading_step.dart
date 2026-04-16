import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';



class SentenceReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SentenceReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SentenceReadingStep> createState() => _SentenceReadingStepState();
}

class _SentenceReadingStepState extends State<SentenceReadingStep> {
  late final SentenceReadingConfig _config;

  int _itemIndex = 0;
  bool _selfReadEnabled = false;

  

  SentenceReadingItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

 

  @override
  void initState() {
    super.initState();
    _config = SentenceReadingConfig.fromMap(widget.step.config);
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

 

  void _handleSelfReadToggle(bool value) {
    setState(() => _selfReadEnabled = value);
  }

  void _handleNextWord() {
    if (_isLastItem) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _itemIndex += 1;
      _selfReadEnabled = false;
    });
    _publishUiState();
  }

 

  @override
  Widget build(BuildContext context) {
    if (_config.items.isEmpty) {
      return const Center(child: Text('No items configured.'));
    }

    final item = _item;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                minHeight: constraints.maxHeight - 48,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    current: _itemIndex + 1,
                    total: _config.items.length,
                  ),
                  const SizedBox(height: 24),
                  _InstructionSection(
                    stepKey: widget.step.key,
                    title: _config.title,
                    instructionAudioUrl: _config.instructionAudioUrl,
                  ),
                  const SizedBox(height: 24),
                  _TokenRow(tokens: item.displayTokens),
                  const SizedBox(height: 20),
                  _SentenceAudioSection(
                    stepKey: widget.step.key,
                    itemIndex: _itemIndex,
                    item: item,
                    selfReadEnabled: _selfReadEnabled,
                    onSelfReadToggle: _handleSelfReadToggle,
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
                  _NextWordButton(
                    label: _isLastItem ? 'Finish' : 'Next Word',
                    onPressed: _handleNextWord,
                  ),
                ],
              ),
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
          'Sentence $safeCurrent of $safeTotal',
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
            minHeight: 8,
            backgroundColor: const Color(0xFFF3E8DD),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.copBlue),
          ),
        ),
      ],
    );
  }
}



class _InstructionSection extends StatelessWidget {
  final String stepKey;
  final String title;
  final String instructionAudioUrl;

  const _InstructionSection({
    required this.stepKey,
    required this.title,
    required this.instructionAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (instructionAudioUrl.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-instruction',
            url: instructionAudioUrl,
            backgroundColor: AppColors.primaryColor,
          )
        else
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.play_arrow, color: Colors.white, size: 28),
          ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
            ),
          ),
        ],
      ],
    );
  }
}



class _TokenRow extends StatelessWidget {
  final List<String> tokens;

  const _TokenRow({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: tokens.map((token) => _TokenPill(token: token)).toList(),
      ),
    );
  }
}

class _TokenPill extends StatelessWidget {
  final String token;

  const _TokenPill({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D0C7), width: 1),
      ),
      child: Text(
        token,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF171B22),
        ),
      ),
    );
  }
}



class _SentenceAudioSection extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final SentenceReadingItem item;
  final bool selfReadEnabled;
  final ValueChanged<bool> onSelfReadToggle;

  const _SentenceAudioSection({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
    required this.selfReadEnabled,
    required this.onSelfReadToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selfReadLabel = item.selfReadLabel.isNotEmpty
        ? item.selfReadLabel
        : 'Read by myself';

    return Column(
      children: [
        // Quoted sentence text
        if (item.sentenceText.isNotEmpty)
          Text(
            '"${item.sentenceText}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171B22),
              height: 1.4,
            ),
          ),
        const SizedBox(height: 16),

        // Waveform audio player — hidden when self-read is toggled on
        AnimatedCrossFade(
          firstChild: _WaveformPlayer(
            stepKey: stepKey,
            itemIndex: itemIndex,
            audioUrl: item.sentenceAudioUrl,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: selfReadEnabled
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),

        if (!selfReadEnabled) const SizedBox(height: 14),

        // "Read by myself" toggle
        _SelfReadToggle(
          label: selfReadLabel,
          value: selfReadEnabled,
          onChanged: onSelfReadToggle,
        ),
      ],
    );
  }
}



class _WaveformPlayer extends StatefulWidget {
  final String stepKey;
  final int itemIndex;
  final String audioUrl;

  const _WaveformPlayer({
    required this.stepKey,
    required this.itemIndex,
    required this.audioUrl,
  });

  @override
  State<_WaveformPlayer> createState() => _WaveformPlayerState();
}

class _WaveformPlayerState extends State<_WaveformPlayer>
    with SingleTickerProviderStateMixin {
  bool _playing = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _animController.repeat(reverse: true);
    } else {
      _animController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        ),
        child: Row(
          children: [
            // Play/pause button
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Waveform bars
            Expanded(
              child: _WaveformBars(
                controller: _animController,
                playing: _playing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final AnimationController controller;
  final bool playing;

  // Fixed height ratios for visual variety (mimic a realistic waveform).
  static const List<double> _heightRatios = [
    0.30, 0.55, 0.75, 0.90, 0.65, 1.00, 0.80, 0.55, 0.95, 0.70,
    0.45, 0.85, 0.60, 1.00, 0.75, 0.50, 0.90, 0.65, 0.40, 0.80,
    0.55, 0.70, 0.95, 0.60, 0.35, 0.75, 0.50, 0.88, 0.65, 0.40,
  ];

  const _WaveformBars({
    required this.controller,
    required this.playing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heightRatios.length, (i) {
            // Each bar gets a slight phase offset when playing.
            double scale = playing
                ? (0.4 +
                    0.6 *
                        (0.5 +
                                0.5 *
                                    (controller.value * 2 * 3.14159 +
                                                i * 0.4)
                                        .clamp(-100.0, 100.0)
                                        .abs() %
                                1.0)
                            .clamp(0.0, 1.0))
                : 0.35;

            return Container(
              width: 3,
              height: 32 * _heightRatios[i] * scale,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}



class _SelfReadToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SelfReadToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryColor.withOpacity(0.08)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value
                ? AppColors.primaryColor
                : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom pill toggle indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primaryColor
                    : const Color(0xFFD9D0C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value
                    ? AppColors.primaryColor
                    : AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _NextWordButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NextWordButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}