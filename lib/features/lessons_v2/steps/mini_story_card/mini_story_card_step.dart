import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';

class MiniStoryCardStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MiniStoryCardStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MiniStoryCardStep> createState() => _MiniStoryCardStepState();
}

class _MiniStoryCardStepState extends State<MiniStoryCardStep> {
  late final MiniStoryCardConfig _config;

  int _itemIndex = 0;
  bool _accordionExpanded = false;

  MiniStoryCardItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

  @override
  void initState() {
    super.initState();
    _config = MiniStoryCardConfig.fromMap(widget.step.config);
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

  void _handleNext() {
    if (_isLastItem) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _itemIndex += 1;
      _accordionExpanded = false;
    });
    _publishUiState();
  }

  void _toggleAccordion() {
    setState(() => _accordionExpanded = !_accordionExpanded);
  }

  @override
  Widget build(BuildContext context) {
    if (_config.items.isEmpty) {
      return const Center(child: Text('No story cards configured.'));
    }

    final item = _item;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: LessonStepCard(
        color: const Color(0xFFF5F3F0),
        elevation: 3,
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonStepProgressHeader(
              current: _itemIndex + 1,
              total: _config.items.length,
              itemLabel: 'Word',
              barColor: AppColors.copBlue,
              barHeight: 8,
              barBackgroundColor: const Color(0xFFDDD8D1),
            ),
            const SizedBox(height: 20),
            Center(
              child: LessonAudioInlineButton(
                sourceId: '${widget.step.key}-top-story-${_itemIndex}',
                url: item.storyAudioUrl,
                isCircular: true,
                backgroundColor: AppColors.primaryColor,
                iconColor: Colors.white,
                defaultIcon: Icons.play_arrow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
            _StoryCard(
              stepKey: widget.step.key,
              itemIndex: _itemIndex,
              item: item,
            ),
            const SizedBox(height: 14),
            _MiniStoryPlaybackPreview(
              sourceId: '${widget.step.key}-story-preview-${_itemIndex}',
              audioUrl: item.storyAudioUrl,
            ),
            const SizedBox(height: 12),
            _ModelReadingAccordion(
              stepKey: widget.step.key,
              itemIndex: _itemIndex,
              item: item,
              expanded: _accordionExpanded,
              onToggle: _toggleAccordion,
            ),
            const SizedBox(height: 16),
            LessonStepNextButton(
              label: _isLastItem
                  ? (item.ctaLabel ?? 'Finish')
                  : (item.ctaLabel ?? 'Next Word'),
              onPressed: _handleNext,
              borderRadius: 28,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final MiniStoryCardItem item;

  const _StoryCard({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bodyLines = item.bodyLines
        .where((line) => line.trim() != item.heading.trim())
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (bodyLines.isNotEmpty) ...[
            ...bodyLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStoryPlaybackPreview extends StatelessWidget {
  final String sourceId;
  final String audioUrl;

  const _MiniStoryPlaybackPreview({
    required this.sourceId,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E3DC)),
        ),
        child: Row(
          children: [
            LessonAudioInlineButton(
              sourceId: sourceId,
              url: audioUrl,
              isCircular: true,
              buttonSize: 40,
              backgroundColor: AppColors.primaryColor,
              iconColor: Colors.white,
              defaultIcon: Icons.play_arrow,
            ),
            const SizedBox(width: 10),
            const Expanded(child: _MiniStoryWaveformPlaceholder()),
          ],
        ),
      ),
    );
  }
}

class _MiniStoryWaveformPlaceholder extends StatelessWidget {
  const _MiniStoryWaveformPlaceholder();

  static const List<double> _heights = [
    6, 10, 16, 12, 18, 10, 20, 14, 22, 12, 16, 8, 18,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _heights
            .map(
              (height) => Container(
                width: 3.5,
                height: height - 2,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ModelReadingAccordion extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final MiniStoryCardItem item;
  final bool expanded;
  final VoidCallback onToggle;

  const _ModelReadingAccordion({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Tap here',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171B22),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'word for model reading',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _PhonemeChips(
              stepKey: stepKey,
              itemIndex: itemIndex,
              item: item,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PhonemeChips extends StatefulWidget {
  final String stepKey;
  final int itemIndex;
  final MiniStoryCardItem item;

  const _PhonemeChips({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
  });

  @override
  State<_PhonemeChips> createState() => _PhonemeChipsState();
}

class _PhonemeChipsState extends State<_PhonemeChips> {
  int? _highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final letters = widget.item.heading
        .toLowerCase()
        .split('')
        .where((c) => c.trim().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(letters.length, (i) {
          final isHighlighted = _highlightedIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => setState(() {
                _highlightedIndex = isHighlighted ? null : i;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60,
                height: 44,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFFFAEDE6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighlighted
                        ? AppColors.primaryColor
                        : const Color(0xFFD9D5CF),
                    width: isHighlighted ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '/${letters[i]}/',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted
                        ? AppColors.primaryColor
                        : AppColors.textColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}