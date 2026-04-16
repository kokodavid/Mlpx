import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';

// ---------------------------------------------------------------------------
// Step widget
// ---------------------------------------------------------------------------

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

  // ── Accessors ─────────────────────────────────────────────────────────────

  MiniStoryCardItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

  // ── Interaction ───────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_config.items.isEmpty) {
      return const Center(child: Text('No story cards configured.'));
    }

    final item = _item;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Progress header ──────────────────────────────────────
                _Header(
                  current: _itemIndex + 1,
                  total: _config.items.length,
                ),
                const SizedBox(height: 20),

                // ── Instruction audio + title ────────────────────────────
                _InstructionSection(
                  stepKey: widget.step.key,
                  title: _config.title,
                  instructionAudioUrl: _config.instructionAudioUrl,
                ),
                const SizedBox(height: 16),

                // ── Story card ───────────────────────────────────────────
                _StoryCard(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                ),
                const SizedBox(height: 14),

                // ── Chevron ──────────────────────────────────────────────
                const Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: AppColors.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Accordion ────────────────────────────────────────────
                _ModelReadingAccordion(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                  expanded: _accordionExpanded,
                  onToggle: _toggleAccordion,
                ),
                const SizedBox(height: 16),

                // ── Next / Finish button ─────────────────────────────────
                _NextButton(
                  label: _isLastItem
                      ? (item.ctaLabel ?? 'Finish')
                      : (item.ctaLabel ?? 'Next Word'),
                  onPressed: _handleNext,
                ),
              ],
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
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: 8,
            backgroundColor: AppColors.accentColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryColor,
            ),
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
  final String? instructionAudioUrl;

  const _InstructionSection({
    required this.stepKey,
    required this.title,
    this.instructionAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (instructionAudioUrl != null && instructionAudioUrl!.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-instruction',
            url: instructionAudioUrl!,
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
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
          ),
        const SizedBox(height: 10),
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
    );
  }
}

// ---------------------------------------------------------------------------
// _StoryCard  — white rounded card with image placeholder, word, audio btn
// ---------------------------------------------------------------------------

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Image area ──────────────────────────────────────────────────
          _StoryImageArea(
            stepKey: stepKey,
            itemIndex: itemIndex,
            item: item,
          ),
          const SizedBox(height: 14),

          // ── Heading / word ──────────────────────────────────────────────
          Text(
            item.heading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
            ),
          ),
          const SizedBox(height: 10),

          // ── Story audio button ──────────────────────────────────────────
          LessonAudioInlineButton(
            sourceId: '$stepKey-story-$itemIndex',
            url: item.storyAudioUrl,
            backgroundColor: const Color(0xFFF5F4F0),
          ),

          // ── Body lines (shown below audio) ──────────────────────────────
          if (item.bodyLines.isNotEmpty &&
              item.bodyLines.first.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...item.bodyLines.map(
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

// ---------------------------------------------------------------------------
// _StoryImageArea — rounded image container (uses network image or placeholder)
// ---------------------------------------------------------------------------

class _StoryImageArea extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final MiniStoryCardItem item;

  const _StoryImageArea({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    // The config doesn't define an image_url field, so we show a neutral
    // placeholder container. If an image_url were added later, swap the child.
    return Container(
      width: 180,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Color(0xFFCCC8C0),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ModelReadingAccordion
// ---------------------------------------------------------------------------

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ────────────────────────────────────────────────
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

          // ── Expanded phoneme chips ─────────────────────────────────────
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

// ---------------------------------------------------------------------------
// _PhonemeChips — row of /c/ /a/ /t/ style chips inside the accordion
// ---------------------------------------------------------------------------

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
    // Build one chip per character of the heading word.
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
                        : AppColors.borderColor,
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

// ---------------------------------------------------------------------------
// _NextButton
// ---------------------------------------------------------------------------

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}