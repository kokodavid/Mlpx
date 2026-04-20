import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_audio_providers.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import '../../services/lesson_audio_controller.dart';
import 'model.dart';

class WordReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const WordReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<WordReadingStep> createState() => _WordReadingStepState();
}

class _WordReadingStepState extends State<WordReadingStep> {
  late final WordReadingConfig _config;

  int _itemIndex = 0;
  bool _segmentsExpanded = false;

  WordReadingItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

  @override
  void initState() {
    super.initState();
    _config = WordReadingConfig.fromMap(widget.step.config);
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

  void _handleNextWord() {
    if (_isLastItem) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _itemIndex += 1;
      _segmentsExpanded = false;
    });
    _publishUiState();
  }

  void _toggleSegments() {
    setState(() => _segmentsExpanded = !_segmentsExpanded);
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
          LessonStepCard(
            color: Colors.white,
            elevation: 3,
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LessonStepProgressHeader(
                  current: _itemIndex + 1,
                  total: _config.items.length,
                  itemLabel: 'Word',
                  barColor: AppColors.copBlue,
                  barBackgroundColor: const Color(0xFFDDD8D1),
                ),
                const SizedBox(height: 18),
                LessonStepInstructionSection(
                  stepKey: widget.step.key,
                  title: _config.title,
                  audioUrl: _config.instructionAudioUrl,
                  audioButtonIsCircular: true,
                  audioButtonDefaultIcon: Icons.play_arrow,
                ),
                const SizedBox(height: 18),
                _WordCard(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                ),
                const SizedBox(height: 14),
                const LessonStepChevronDown(),
                const SizedBox(height: 14),
                _ModelReadingAccordion(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                  expanded: _segmentsExpanded,
                  onToggle: _toggleSegments,
                ),
                const SizedBox(height: 18),
                LessonStepNextButton(
                  label: _isLastItem ? 'Finish' : 'Next Word',
                  onPressed: _handleNextWord,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final WordReadingItem item;

  const _WordCard({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 196),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0EBE4), width: 1),
        ),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textColor,
                          size: 42,
                        ),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textColor,
                            size: 42,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.word,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
            if (item.wordAudioUrl.isNotEmpty)
              LessonAudioInlineButton(
                sourceId: '$stepKey-item-$itemIndex-word',
                url: item.wordAudioUrl,
                backgroundColor: const Color(0xFFF8F8F8),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelReadingAccordion extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final WordReadingItem item;
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
    final label = item.modelReadingLabel.isNotEmpty
        ? item.modelReadingLabel
        : 'model reading';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Tap here ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: 'word for $label'),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _SegmentRow(
                stepKey: stepKey,
                itemIndex: itemIndex,
                segments: item.segments,
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final List<WordSegment> segments;

  const _SegmentRow({
    required this.stepKey,
    required this.itemIndex,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(segments.length, (i) {
        return _SegmentTile(
          sourceId: '$stepKey-item-$itemIndex-seg-$i',
          segment: segments[i],
        );
      }),
    );
  }
}

class _SegmentTile extends ConsumerWidget {
  final String sourceId;
  final WordSegment segment;

  const _SegmentTile({
    required this.sourceId,
    required this.segment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(lessonAudioControllerProvider);
    return _SegmentTileStateful(
      segment: segment,
      onTap: () {
        controller.playUrl(segment.audioUrl, sourceId: sourceId);
      },
    );
  }
}

class _SegmentTileStateful extends StatefulWidget {
  final WordSegment segment;
  final VoidCallback onTap;

  const _SegmentTileStateful({
    required this.segment,
    required this.onTap,
  });

  @override
  State<_SegmentTileStateful> createState() => _SegmentTileStatefulState();
}

class _SegmentTileStatefulState extends State<_SegmentTileStateful> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.segment.highlighted;

    final borderColor = highlighted
        ? AppColors.primaryColor
        : (_tapped ? AppColors.primaryColor : const Color(0xFFD9D0C7));

    final bgColor = highlighted
        ? AppColors.primaryColor.withOpacity(0.07)
        : (_tapped ? AppColors.primaryColor.withOpacity(0.05) : Colors.white);

    final textColor =
        (highlighted || _tapped) ? AppColors.primaryColor : AppColors.textColor;

    return GestureDetector(
      onTap: () {
        setState(() => _tapped = true);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: highlighted ? 2.0 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.segment.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
