import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
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

  void _handleBlend() {
    setState(() => _blended = true);
  }

  void _handleNext() {
    if (_isLastExample) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _exampleIndex += 1;
      _blended = false;
    });
    _publishUiState();
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonStepProgressHeader(
                  current: _exampleIndex + 1,
                  total: _config.examples.length,
                  itemLabel: 'Letter',
                ),
                const SizedBox(height: 20),
                LessonStepInstructionSection(
                  stepKey: widget.step.key,
                  title: _config.instruction,
                  audioUrl: _config.instructionAudioUrl,
                ),
                const SizedBox(height: 20),
                _PhonemeRow(
                  stepKey: widget.step.key,
                  exampleIndex: _exampleIndex,
                  phonemes: example.phonemes,
                ),
                const SizedBox(height: 14),
                const LessonStepChevronDown(),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
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
                        )
                      : const SizedBox.shrink(key: ValueKey<String>('blank')),
                ),
                const SizedBox(height: 16),
                _buildBottomAction(example),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(BlendingExample example) {
    if (_blended) {
      return LessonStepNextButton(
        label: _isLastExample ? 'Finish' : 'Next Question',
        onPressed: _handleNext,
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

  const _PhonemeRow({
    required this.stepKey,
    required this.exampleIndex,
    required this.phonemes,
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _PhonemeButton(
              sourceId: '$stepKey-example-$exampleIndex-phoneme-$i',
              phoneme: phonemes[i],
            ),
          );
        }),
      ),
    );
  }
}

class _PhonemeButton extends StatefulWidget {
  final String sourceId;
  final BlendingPhoneme phoneme;

  const _PhonemeButton({
    required this.sourceId,
    required this.phoneme,
  });

  @override
  State<_PhonemeButton> createState() => _PhonemeButtonState();
}

class _PhonemeButtonState extends State<_PhonemeButton> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.phoneme.highlighted;
    final label = '/${widget.phoneme.label}/';

    final borderColor = highlighted
        ? AppColors.primaryColor
        : (_tapped ? AppColors.primaryColor : const Color(0xFFD9D0C7));

    final bgColor = highlighted
        ? AppColors.primaryColor.withOpacity(0.07)
        : (_tapped ? AppColors.primaryColor.withOpacity(0.05) : Colors.white);

    return GestureDetector(
      onTap: () => setState(() => _tapped = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: highlighted ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: highlighted
                ? AppColors.primaryColor
                : (_tapped ? AppColors.primaryColor : AppColors.textColor),
          ),
        ),
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

  const _BlendedWordDisplay({
    super.key,
    required this.stepKey,
    required this.exampleIndex,
    required this.example,
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
      final lowerLabel = phoneme.label.toLowerCase();
      final matchIndex = lowerWord.indexOf(lowerLabel, cursor);
      if (matchIndex < 0) continue;

      if (matchIndex > cursor) {
        spans.add(TextSpan(
          text: word.substring(cursor, matchIndex),
          style: const TextStyle(color: Color(0xFF171B22)),
        ));
      }

      spans.add(TextSpan(
        text: word.substring(matchIndex, matchIndex + lowerLabel.length),
        style: TextStyle(
          color: phoneme.highlighted
              ? AppColors.primaryColor
              : const Color(0xFF171B22),
        ),
      ));

      cursor = matchIndex + lowerLabel.length;
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