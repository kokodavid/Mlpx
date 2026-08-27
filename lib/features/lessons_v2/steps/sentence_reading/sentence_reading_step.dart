import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.step.key.isNotEmpty) ...[
            LessonStepTitle(title: widget.step.key),
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
                  current: _itemIndex + 1,
                  total: _config.items.length,
                  itemLabel: 'Sentence',
                  barColor: AppColors.copBlue,
                  barHeight: 8,
                  barBackgroundColor: const Color(0xFFDDD8D1),
                ),
                const SizedBox(height: 24),
                LessonStepInstructionSection(
                  stepKey: widget.step.key,
                  title: _config.title,
                  audioUrl: _config.instructionAudioUrl,
                  audioButtonIsCircular: true,
                  audioButtonDefaultIcon: Icons.play_arrow,
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
                const LessonStepChevronDown(
                  color: Color(0xFF8A8A8A),
                  size: 26,
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 220,
                    child: LessonStepNextButton(
                      label: _isLastItem ? 'Finish' : 'Next Word',
                      onPressed: _handleNextWord,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DC), width: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D5CF), width: 1),
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
        if (item.sentenceText.isNotEmpty)
          Text(
            item.sentenceText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171B22),
              height: 1.4,
            ),
          ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          firstChild: LessonWaveformPlayer(
            sourceId: '$stepKey-sentence-$itemIndex-audio',
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
        _SelfReadToggle(
          label: selfReadLabel,
          value: selfReadEnabled,
          onChanged: onSelfReadToggle,
        ),
      ],
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
          color:
              value ? AppColors.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.primaryColor : const Color(0xFFD9D5CF),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color:
                    value ? AppColors.primaryColor : const Color(0xFFD9D0C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
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
                color: value ? AppColors.primaryColor : AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}