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
                LessonStepProgressHeader(
                  current: _itemIndex + 1,
                  total: _config.items.length,
                  itemLabel: 'Word',
                  barBackgroundColor: AppColors.accentColor,
                ),
                const SizedBox(height: 20),
                LessonStepInstructionSection(
                  stepKey: widget.step.key,
                  title: _config.title,
                  audioUrl: _config.instructionAudioUrl ?? '',
                ),
                const SizedBox(height: 16),
                _StoryCard(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                ),
                const SizedBox(height: 14),
                const LessonStepChevronDown(),
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
      },
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
          _StoryImageArea(stepKey: stepKey, itemIndex: itemIndex, item: item),
          const SizedBox(height: 14),
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
          LessonAudioInlineButton(
            sourceId: '$stepKey-story-$itemIndex',
            url: item.storyAudioUrl,
            backgroundColor: const Color(0xFFF5F4F0),
          ),
          if (item.bodyLines.isNotEmpty && item.bodyLines.first.isNotEmpty) ...[
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