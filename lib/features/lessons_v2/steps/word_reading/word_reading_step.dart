import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';

// ---------------------------------------------------------------------------
// Step widget
// ---------------------------------------------------------------------------

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

  // ── Accessors ─────────────────────────────────────────────────────────────

  WordReadingItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

  // ── Interaction handlers ──────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 312),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
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
                  const SizedBox(height: 18),
                  _InstructionSection(
                    stepKey: widget.step.key,
                    title: _config.title,
                    instructionAudioUrl: _config.instructionAudioUrl,
                  ),
                  const SizedBox(height: 18),
                  _WordCard(
                    stepKey: widget.step.key,
                    itemIndex: _itemIndex,
                    item: item,
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Icon(
                      Icons.keyboard_double_arrow_down_rounded,
                      color: AppColors.textColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ModelReadingAccordion(
                    stepKey: widget.step.key,
                    itemIndex: _itemIndex,
                    item: item,
                    expanded: _segmentsExpanded,
                    onToggle: _toggleSegments,
                  ),
                  const SizedBox(height: 18),
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

// ---------------------------------------------------------------------------
// _Header
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// _InstructionSection
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// _WordCard  — image + word label + word audio button
// ---------------------------------------------------------------------------

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
            // Image area
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
            // Word label
            Text(
              item.word,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
            // Word audio button
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

// ---------------------------------------------------------------------------
// _ModelReadingAccordion  — collapsible row showing phoneme segments
// ---------------------------------------------------------------------------

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
          // Header row — always visible
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          TextSpan(
                            text: 'word for $label',
                          ),
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
          // Expanded segment row
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
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SegmentRow  — tappable phoneme tiles, mirrors BlendingStep style
// ---------------------------------------------------------------------------

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

class _SegmentTile extends StatefulWidget {
  final String sourceId;
  final WordSegment segment;

  const _SegmentTile({
    required this.sourceId,
    required this.segment,
  });

  @override
  State<_SegmentTile> createState() => _SegmentTileState();
}

class _SegmentTileState extends State<_SegmentTile> {
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

    final textColor = (highlighted || _tapped)
        ? AppColors.primaryColor
        : AppColors.textColor;

    final borderWidth = highlighted ? 2.0 : 1.0;

    return GestureDetector(
      onTap: () => setState(() => _tapped = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
            style: highlighted && !_tapped ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '/${widget.segment.label}/',
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

// ---------------------------------------------------------------------------
// _NextWordButton
// ---------------------------------------------------------------------------

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