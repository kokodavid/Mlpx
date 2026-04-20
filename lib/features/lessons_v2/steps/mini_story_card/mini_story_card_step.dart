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
    });
    _publishUiState();
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
        color: Colors.white,
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
            const SizedBox(height: 20),
            Center(
              child: LessonAudioInlineButton(
                sourceId: '${widget.step.key}-top-story-$_itemIndex',
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
              sourceId: '${widget.step.key}-story-preview-$_itemIndex',
              audioUrl: item.storyAudioUrl,
            ),
            const SizedBox(height: 10),
            _ListenToSentenceButton(
              sourceId: '${widget.step.key}-listen-$_itemIndex',
              audioUrl: item.storyAudioUrl,
              label: item.ctaLabel ?? 'Listen to the sentence',
            ),
            const SizedBox(height: 16),
            LessonStepNextButton(
              label: _isLastItem ? 'Finish' : 'Continue',
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
          if (bodyLines.isNotEmpty)
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
        width: double.infinity,
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

class _ListenToSentenceButton extends StatelessWidget {
  final String sourceId;
  final String audioUrl;
  final String label;

  const _ListenToSentenceButton({
    required this.sourceId,
    required this.audioUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          side: const BorderSide(color: Color(0xFFE8E3DC), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
      ),
    );
  }
}