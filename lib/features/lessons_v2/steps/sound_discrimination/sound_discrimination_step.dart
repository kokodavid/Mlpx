import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import 'model.dart';

class SoundDiscriminationStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final VoidCallback onAdvanceRequested;

  const SoundDiscriminationStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.onAdvanceRequested,
  });

  @override
  State<SoundDiscriminationStep> createState() =>
      _SoundDiscriminationStepState();
}

class _SoundDiscriminationStepState extends State<SoundDiscriminationStep> {
  late final SoundDiscriminationConfig _config;
  int _currentItemIndex = 0;
  bool? _selectedAnswer;

  SoundDiscriminationItem get _currentItem =>
      _config.items[_currentItemIndex.clamp(0, _config.items.length - 1)];

  bool get _isCorrect =>
      _selectedAnswer != null &&
      _selectedAnswer == _currentItem.containsTargetSound;

  bool get _isLastItem => _currentItemIndex >= _config.items.length - 1;

  @override
  void initState() {
    super.initState();
    _config = SoundDiscriminationConfig.fromMap(widget.step.config);
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

  void _handleAnswer(bool answer) {
    setState(() => _selectedAnswer = answer);
    _publishUiState();
  }

  void _handleReview() {
    setState(() => _selectedAnswer = null);
    _publishUiState();
  }

  void _handleContinue() {
    if (!_isCorrect) {
      _handleReview();
      return;
    }
    if (_isLastItem) {
      widget.onAdvanceRequested();
      return;
    }
    setState(() {
      _currentItemIndex += 1;
      _selectedAnswer = null;
    });
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonStepTitle(title: _config.title),
                const SizedBox(height: 16),
                LessonStepCard(
                  color: const Color(0xFFF6F6F6),
                  elevation: 2,
                  borderRadius: 28,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LessonStepProgressHeader(
                        current: _currentItemIndex + 1,
                        total: _config.items.length,
                        itemLabel: 'Activity',
                        barColor: AppColors.copBlue,
                        barHeight: 10,
                        barBackgroundColor: const Color(0xFFF3E8DD),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: LessonAudioInlineButton(
                          sourceId:
                              'sound_discrimination_title_$_currentItemIndex',
                          url: item.titleAudioUrl,
                          isCircular: true,
                          buttonSize: 40,
                          backgroundColor: AppColors.primaryColor,
                          iconColor: Colors.white,
                          defaultIcon: Icons.play_arrow,
                        ),
                      ),
                      if (_config.instructionText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _config.instructionText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171B22),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _PromptCard(
                        stepKey: widget.step.key,
                        itemIndex: _currentItemIndex,
                        title: item.title,
                        highlightedText: item.highlightedText,
                        imageUrl: item.imageUrl,
                        audioUrl: item.titleAudioUrl,
                      ),
                      const SizedBox(height: 8),
                      const LessonStepChevronDown(
                          color: AppColors.copBlue, size: 24),
                      const SizedBox(height: 8),
                      LessonStepTipBanner(
                        text: _buildTipText(),
                        borderRadius: 16,
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _selectedAnswer == null
                            ? _buildAnswerButtons()
                            : LessonFeedbackBar(
                                key: ValueKey<String>(
                                  'feedback-$_currentItemIndex-$_isCorrect',
                                ),
                                isCorrect: _isCorrect,
                                message: _isCorrect
                                    ? 'Yes! "${item.title}" has the ${_config.displayTargetSound} sound.'
                                    : 'Listen again for ${_config.displayTargetSound} like in "${_config.referenceWord}".',
                                actionLabel: _isCorrect ? 'Continue' : 'Review',
                                onActionPressed: _isCorrect
                                    ? _handleContinue
                                    : _handleReview,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildTipText() {
    if (_config.referenceWord.isEmpty) return _config.tipText;
    if (_config.tipText.contains(_config.referenceWord)) return _config.tipText;
    return '${_config.tipText}, like in "${_config.referenceWord}".';
  }

  Widget _buildAnswerButtons() {
    return Padding(
      key: ValueKey<String>('choices-$_currentItemIndex'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: _AnswerButton(
              label: 'Yes, ${_config.displayTargetSound}',
              borderColor: AppColors.successColor,
              foregroundColor: AppColors.successColor,
              onPressed: () => _handleAnswer(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AnswerButton(
              label: 'No, Not ${_config.displayTargetSound}',
              borderColor: AppColors.errorColor,
              foregroundColor: AppColors.errorColor,
              onPressed: () => _handleAnswer(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final String title;
  final String highlightedText;
  final String imageUrl;
  final String audioUrl;

  const _PromptCard({
    required this.stepKey,
    required this.itemIndex,
    required this.title,
    required this.highlightedText,
    required this.imageUrl,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 194,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF4F1EC)),
        ),
        child: Column(
          children: [
            Container(
              height: 132,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textColor,
                          size: 40,
                        ),
                      )
                    : Image.network(
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
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B22),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            LessonAudioInlineButton(
              sourceId: '$stepKey-item-$itemIndex',
              url: audioUrl,
              backgroundColor: const Color(0xFFF8F8F8),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.borderColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: foregroundColor.withValues(alpha: 0.06),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
