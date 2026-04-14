import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';

class GuidedWordReadingStep extends StatefulWidget {
  final String instruction;
  final String audioUrl;
  final List<String> phonemes;
  final int highlightedIndex;
  final String word;
  final String vowelLetter;

  const GuidedWordReadingStep({
    super.key,
    required this.instruction,
    required this.audioUrl,
    required this.phonemes,
    required this.highlightedIndex,
    required this.word,
    required this.vowelLetter,
  });

  @override
  State<GuidedWordReadingStep> createState() => _GuidedWordReadingStepState();
}

class _GuidedWordReadingStepState extends State<GuidedWordReadingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  String get _instruction => widget.instruction.isNotEmpty
      ? widget.instruction
      : 'Listen to the sounds. Then\nhear the whole word';

  List<String> get _phonemes =>
      widget.phonemes.isNotEmpty ? widget.phonemes : const ['/m/', '/a/', '/n/'];

  int get _highlightedIndex {
    if (_phonemes.isEmpty) return 0;
    return widget.highlightedIndex.clamp(0, _phonemes.length - 1);
  }

  String get _word => widget.word.isNotEmpty ? widget.word : 'man';
  String get _audioUrl => widget.audioUrl.isNotEmpty ? widget.audioUrl : '';
  String get _vowelLetter =>
      widget.vowelLetter.isNotEmpty ? widget.vowelLetter : 'a';

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Grey card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Audio play button — rendered at its natural size
                LessonAudioInlineButton(
                  sourceId: 'guided-word-reading-audio',
                  url: _audioUrl,
                  backgroundColor: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                // Instruction — centered
                Text(
                  _instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Phoneme tiles — centered row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_phonemes.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _phonemes.length - 1 ? 0 : 10,
                      ),
                      child: _PhonemeTile(
                        label: _phonemes[index],
                        isHighlighted: index == _highlightedIndex,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Word with highlighted vowel — centered
                _buildHighlightedWord(),
                const SizedBox(height: 4),
                // Double chevron
                const Icon(
                  Icons.keyboard_double_arrow_down,
                  size: 26,
                  color: Colors.black87,
                ),
                const SizedBox(height: 12),
                // Waveform player
                _buildWaveformPlayer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformPlayer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.volume_up,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) => CustomPaint(
                  painter: _WaveformPainter(progress: _waveController.value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedWord() {
    final lowerWord = _word.toLowerCase();
    final lowerVowel = _vowelLetter.toLowerCase();
    final matchIndex = lowerWord.indexOf(lowerVowel);

    if (matchIndex < 0 || lowerVowel.isEmpty) {
      return Text(
        _word,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      );
    }

    final before = _word.substring(0, matchIndex);
    final match =
        _word.substring(matchIndex, matchIndex + _vowelLetter.length);
    final after = _word.substring(matchIndex + _vowelLetter.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

// ── Phoneme tile ───────────────────────────────────────────────────────────────

class _PhonemeTile extends StatelessWidget {
  final String label;
  final bool isHighlighted;

  const _PhonemeTile({required this.label, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: isHighlighted
          ? _DashedRoundedRectPainter(
              color: AppColors.primaryColor,
              radius: 14,
            )
          : null,
      child: Container(
        width: 62,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? null
              : Border.all(color: AppColors.lightGrey, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color:
                isHighlighted ? AppColors.primaryColor : AppColors.copBlue,
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ──────────────────────────────────────────────────────

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRoundedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.8),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter old) =>
      old.color != color || old.radius != radius;
}

// ── Waveform painter ───────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double progress;

  const _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    const bars = 54;
    final spacing = size.width / bars;

    for (int i = 0; i < bars; i++) {
      final normalized = i / bars;
      final wave = math.sin((normalized * 8) + (progress * math.pi * 2));
      final pulse = math.cos((normalized * 15) - (progress * math.pi * 3));
      final amplitude = 6 + ((wave.abs() * 10) + (pulse.abs() * 4));
      final x = (i * spacing) + (spacing / 2);
      canvas.drawLine(
        Offset(x, midY - amplitude / 2),
        Offset(x, midY + amplitude / 2),
        glowPaint,
      );
      canvas.drawLine(
        Offset(x, midY - amplitude / 2),
        Offset(x, midY + amplitude / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress;
}