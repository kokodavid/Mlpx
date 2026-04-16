import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishUiState();
    });
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
    setState(() {
      _selectedAnswer = answer;
    });
    _publishUiState();
  }

  void _handleReview() {
    setState(() {
      _selectedAnswer = null;
    });
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepTitle(
                  stepKey: widget.step.key,
                  title: _config.title,
                  titleAudioUrl: _config.titleAudioUrl,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ActivityHeader(
                          current: _currentItemIndex + 1,
                          total: _config.items.length,
                        ),
                        const SizedBox(height: 20),
                        _PromptCard(
                          stepKey: widget.step.key,
                          itemIndex: _currentItemIndex,
                          title: item.title,
                          highlightedText: item.highlightedText,
                          imageUrl: item.imageUrl,
                          audioUrl: item.titleAudioUrl,
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: AppColors.copBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TipCard(
                          tipText: _config.tipText,
                          referenceWord: _config.referenceWord,
                          displayTargetSound: _config.displayTargetSound,
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _selectedAnswer == null
                              ? Row(
                                  key: ValueKey<String>(
                                      'choices-$_currentItemIndex'),
                                  children: [
                                    Expanded(
                                      child: _AnswerButton(
                                        label:
                                            'Yes, ${_config.displayTargetSound}',
                                        borderColor: AppColors.successColor,
                                        foregroundColor: AppColors.successColor,
                                        onPressed: () => _handleAnswer(true),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _AnswerButton(
                                        label:
                                            'No, Not ${_config.displayTargetSound}',
                                        borderColor: AppColors.errorColor,
                                        foregroundColor: AppColors.errorColor,
                                        onPressed: () => _handleAnswer(false),
                                      ),
                                    ),
                                  ],
                                )
                              : _FeedbackBar(
                                  key: ValueKey<String>(
                                    'feedback-$_currentItemIndex-$_isCorrect',
                                  ),
                                  isCorrect: _isCorrect,
                                  message: _isCorrect
                                      ? '"${item.title}" has the ${_config.displayTargetSound} sound.'
                                      : 'Listen again for ${_config.displayTargetSound} like in "${_config.referenceWord}".',
                                  actionLabel:
                                      _isCorrect ? 'Continue' : 'Review',
                                  onActionPressed: _isCorrect
                                      ? _handleContinue
                                      : _handleReview,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  final int current;
  final int total;

  const _ActivityHeader({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity $safeCurrent of $safeTotal',
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
            minHeight: 10,
            backgroundColor: const Color(0xFFF3E8DD),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.copBlue),
          ),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String stepKey;
  final String title;
  final String titleAudioUrl;

  const _StepTitle({
    required this.stepKey,
    required this.title,
    required this.titleAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171B22),
          ),
        ),
        if (titleAudioUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          LessonAudioInlineButton(
            sourceId: '$stepKey-title',
            url: titleAudioUrl,
            backgroundColor: const Color(0xFFF8F8F8),
          ),
        ],
      ],
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
                color: const Color(0xFFF7F7F7),
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
                        fit: BoxFit.cover,
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
            _HighlightedWord(
              word: title,
              highlightedText: highlightedText,
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

class _HighlightedWord extends StatelessWidget {
  final String word;
  final String highlightedText;

  const _HighlightedWord({
    required this.word,
    required this.highlightedText,
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF171B22),
    );

    if (highlightedText.isEmpty) {
      return Text(
        word,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    final lowerWord = word.toLowerCase();
    final lowerHighlight = highlightedText.toLowerCase();
    final matchIndex = lowerWord.indexOf(lowerHighlight);

    if (matchIndex < 0) {
      return Text(
        word,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    final start = word.substring(0, matchIndex);
    final match =
        word.substring(matchIndex, matchIndex + highlightedText.length);
    final end = word.substring(matchIndex + highlightedText.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: start),
          TextSpan(
            text: match,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          TextSpan(text: end),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tipText;
  final String referenceWord;
  final String displayTargetSound;

  const _TipCard({
    required this.tipText,
    required this.referenceWord,
    required this.displayTargetSound,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = referenceWord.isEmpty ? '' : ', like in "$referenceWord".';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D0C7)),
      ),
      child: Text(
        '$tipText$suffix',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.textColor,
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
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: foregroundColor.withValues(alpha: 0.06),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _FeedbackBar({
    super.key,
    required this.isCorrect,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final backgroundColor =
        isCorrect ? const Color(0xFFF2F8EE) : const Color(0xFFFFF1F0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: borderColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: borderColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: borderColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
