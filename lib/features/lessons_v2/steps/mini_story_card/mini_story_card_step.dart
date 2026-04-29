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
    setState(() => _itemIndex += 1);
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
                _StoryCard(item: item),
                const SizedBox(height: 14),
                LessonWaveformPlayer(
                  sourceId: '${widget.step.key}-story-preview-$_itemIndex',
                  audioUrl: item.storyAudioUrl,
                ),
                const SizedBox(height: 10),
                _ListenToSentenceButton(
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
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final MiniStoryCardItem item;

  const _StoryCard({required this.item});

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

class _ListenToSentenceButton extends StatelessWidget {
  final String label;

  const _ListenToSentenceButton({required this.label});

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