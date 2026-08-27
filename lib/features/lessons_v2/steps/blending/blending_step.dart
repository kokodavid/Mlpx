import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_audio_providers.dart';
import 'model.dart';

class BlendingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const BlendingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<BlendingStep> createState() => _BlendingStepState();
}

class _BlendingStepState extends State<BlendingStep> {
  late final BlendingConfig _config;

  int _exampleIndex = 0;
  bool _blended = false;
  final Set<String> _selectedPhonemeIds = {};

  BlendingExample get _example =>
      _config.examples[_exampleIndex.clamp(0, _config.examples.length - 1)];

  bool get _isLastExample => _exampleIndex >= _config.examples.length - 1;

  @override
  void initState() {
    super.initState();
    _config = BlendingConfig.fromMap(widget.step.config);
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

  void _handleBlend() => setState(() => _blended = true);

  void _handleNext() {
    if (_isLastExample) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _exampleIndex += 1;
      _blended = false;
      _selectedPhonemeIds.clear();
    });
    _publishUiState();
  }

  void _handlePhonemeSelected(String sourceId) {
    setState(() => _selectedPhonemeIds.add(sourceId));
  }

  @override
  Widget build(BuildContext context) {
    if (_config.examples.isEmpty) {
      return const Center(child: Text('No examples configured.'));
    }

    final example = _example;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_config.title.isNotEmpty) ...[
                LessonStepTitle(title: _config.title),
                const SizedBox(height: 6),
              ],
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: LessonStepCard(
                    color: const Color(0xFFF6F6F6),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LessonStepProgressHeader(
                          current: _exampleIndex + 1,
                          total: _config.examples.length,
                          itemLabel: 'Letter',
                          barColor: AppColors.copBlue,
                          barBackgroundColor: const Color(0xFFDDD8D1),
                        ),
                        const SizedBox(height: 20),
                        LessonStepInstructionSection(
                          stepKey: widget.step.key,
                          title: _config.instruction,
                          audioUrl: _config.instructionAudioUrl,
                          audioBackgroundColor: AppColors.primaryColor,
                          audioButtonIsCircular: true,
                          audioButtonDefaultIcon: Icons.play_arrow,
                        ),
                        const SizedBox(height: 20),
                        _PhonemeRow(
                          stepKey: widget.step.key,
                          exampleIndex: _exampleIndex,
                          phonemes: example.phonemes,
                          selectedSourceIds: _selectedPhonemeIds,
                          onPhonemeSelected: _handlePhonemeSelected,
                        ),
                        const SizedBox(height: 14),
                        const LessonStepChevronDown(),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _blended
                              ? _BlendedWordDisplay(
                                  key: ValueKey<String>(
                                      'blended-$_exampleIndex-${example.word}'),
                                  stepKey: widget.step.key,
                                  exampleIndex: _exampleIndex,
                                  example: example,
                                  selectedSourceIds: _selectedPhonemeIds,
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey<String>('blank')),
                        ),
                        if (_blended) ...[
                          const SizedBox(height: 12),
                          const LessonStepTipBanner(
                            text: 'Tip: Tap to Hear, Tap to Blend',
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildBottomAction(example),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(BlendingExample example) {
    if (_blended) {
      return Center(
        child: SizedBox(
          width: 220,
          height: 48,
          child: OutlinedButton(
            onPressed: _handleNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              backgroundColor: AppColors.primaryColor.withOpacity(0.06),
              side: const BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(_isLastExample ? 'Finish' : 'Next Question'),
          ),
        ),
      );
    }

    return _BlendButton(
      stepKey: widget.step.key,
      exampleIndex: _exampleIndex,
      wordAudioUrl: example.wordAudioUrl,
      onBlend: _handleBlend,
    );
  }
}

class _PhonemeRow extends StatelessWidget {
  final String stepKey;
  final int exampleIndex;
  final List<BlendingPhoneme> phonemes;
  final Set<String> selectedSourceIds;
  final ValueChanged<String> onPhonemeSelected;

  const _PhonemeRow({
    required this.stepKey,
    required this.exampleIndex,
    required this.phonemes,
    required this.selectedSourceIds,
    required this.onPhonemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EBE4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(phonemes.length, (i) {
          final sourceId = '$stepKey-example-$exampleIndex-phoneme-$i';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: PhonemeButton.phoneme(
              sourceId: sourceId,
              label: phonemes[i].label,
              audioUrl: phonemes[i].audioUrl,
              highlighted: phonemes[i].highlighted,
              onTap: () => onPhonemeSelected(sourceId),
            ),
          );
        }),
      ),
    );
  }
}

class _BlendButton extends StatelessWidget {
  final String stepKey;
  final int exampleIndex;
  final String wordAudioUrl;
  final VoidCallback onBlend;

  const _BlendButton({
    required this.stepKey,
    required this.exampleIndex,
    required this.wordAudioUrl,
    required this.onBlend,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onBlend,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: AppColors.primaryColor.withOpacity(0.06),
          side: const BorderSide(color: AppColors.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Blend'),
      ),
    );
  }
}

class _BlendedWordDisplay extends StatelessWidget {
  final String stepKey;
  final int exampleIndex;
  final BlendingExample example;
  final Set<String> selectedSourceIds;

  const _BlendedWordDisplay({
    super.key,
    required this.stepKey,
    required this.exampleIndex,
    required this.example,
    required this.selectedSourceIds,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _HighlightedBlendedWord(
        word: example.word,
        phonemes: example.phonemes,
      ),
    );
  }
}

class _HighlightedBlendedWord extends StatelessWidget {
  final String word;
  final List<BlendingPhoneme> phonemes;

  const _HighlightedBlendedWord({
    required this.word,
    required this.phonemes,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    int cursor = 0;
    final lowerWord = word.toLowerCase();

    for (final phoneme in phonemes) {
      final normalizedLabel =
          phoneme.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalizedLabel.isEmpty) continue;

      final matchIndex = lowerWord.indexOf(normalizedLabel, cursor);
      if (matchIndex < 0) continue;

      if (matchIndex > cursor) {
        spans.add(TextSpan(
          text: word.substring(cursor, matchIndex),
          style: const TextStyle(color: Color(0xFF171B22)),
        ));
      }

      spans.add(TextSpan(
        text: word.substring(matchIndex, matchIndex + normalizedLabel.length),
        style: TextStyle(
          color: phoneme.highlighted
              ? AppColors.primaryColor
              : const Color(0xFF171B22),
        ),
      ));

      cursor = matchIndex + normalizedLabel.length;
    }

    if (cursor < word.length) {
      spans.add(TextSpan(
        text: word.substring(cursor),
        style: const TextStyle(color: Color(0xFF171B22)),
      ));
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }
}