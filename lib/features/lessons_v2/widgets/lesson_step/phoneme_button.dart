import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';

import '../../providers/lesson_audio_providers.dart';
import '../../services/lesson_audio_controller.dart';
import 'lesson_dotted_border_painter.dart';

const Color _lessonDottedBorderColor = AppColors.primaryColor;

enum _PhonemeButtonVariant { phoneme, segment, slot }

enum PhonemeSlotState {
  given,
  empty,
  emptyDotted,
  filled,
  filledError,
}

class PhonemeButton extends ConsumerStatefulWidget {
  final String label;
  final String audioUrl;
  final String sourceId;
  final bool highlighted;
  final VoidCallback? onTap;
  final PhonemeSlotState slotState;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showShadow;
  final double dottedStrokeWidth;
  final double dottedDotSize;
  final double dottedDotGap;
  final _PhonemeButtonVariant _variant;

  const PhonemeButton.phoneme({
    super.key,
    required this.sourceId,
    required this.label,
    required this.audioUrl,
    required this.highlighted,
    required this.onTap,
  })  : _variant = _PhonemeButtonVariant.phoneme,
        slotState = PhonemeSlotState.empty,
        width = 68,
        height = 44,
        borderRadius = 12,
        fontSize = 15,
        fontWeight = FontWeight.w600,
        showShadow = false,
        dottedStrokeWidth = 3.0,
        dottedDotSize = 3.0,
        dottedDotGap = 3.5;

  const PhonemeButton.segment({
    super.key,
    required this.sourceId,
    required this.label,
    required this.audioUrl,
    required this.highlighted,
    this.onTap,
  })  : _variant = _PhonemeButtonVariant.segment,
        slotState = PhonemeSlotState.empty,
        width = 70,
        height = 56,
        borderRadius = 14,
        fontSize = 17,
        fontWeight = FontWeight.w700,
        showShadow = true,
        dottedStrokeWidth = 3.0,
        dottedDotSize = 3.0,
        dottedDotGap = 3.5;

  const PhonemeButton.slot({
    super.key,
    required this.label,
    required this.slotState,
    this.onTap,
  })  : _variant = _PhonemeButtonVariant.slot,
        sourceId = '',
        audioUrl = '',
        highlighted = false,
        width = 52,
        height = 52,
        borderRadius = 14,
        fontSize = 20,
        fontWeight = FontWeight.w700,
        showShadow = false,
        dottedStrokeWidth = 4.0,
        dottedDotSize = 4.0,
        dottedDotGap = 4.5;

  @override
  ConsumerState<PhonemeButton> createState() => _PhonemeButtonState();
}

class _PhonemeButtonState extends ConsumerState<PhonemeButton> {
  bool _tapped = false;

  Future<void> _handleTap() async {
    if (widget._variant == _PhonemeButtonVariant.slot) {
      widget.onTap?.call();
      return;
    }

    setState(() => _tapped = true);
    widget.onTap?.call();

    if (widget.audioUrl.isNotEmpty) {
      ref.read(lessonAudioControllerProvider).playUrl(
            widget.audioUrl,
            sourceId: widget.sourceId,
          );
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget._variant) {
      _PhonemeButtonVariant.phoneme => _buildPhoneme(),
      _PhonemeButtonVariant.segment => _buildSegment(),
      _PhonemeButtonVariant.slot => _buildSlot(),
    };
  }

  Widget _buildPhoneme() {
    final isActive = widget.highlighted || _tapped;
    final bgColor = isActive
        ? AppColors.primaryColor.withOpacity(0.05)
        : const Color(0xFFF3F3F3);

    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: null,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          color: isActive ? AppColors.primaryColor : AppColors.textColor,
        ),
      ),
    );

    final half = widget.dottedStrokeWidth / 2;

    return GestureDetector(
      onTap: _handleTap,
      child: widget.highlighted
          ? CustomPaint(
              painter: LessonDottedBorderPainter(
                color: _lessonDottedBorderColor,
                strokeWidth: widget.dottedStrokeWidth,
                dotSize: widget.dottedDotSize,
                dotGap: widget.dottedDotGap,
                borderRadius: widget.borderRadius + half,
              ),
              child: Padding(
                padding: EdgeInsets.all(half),
                child: inner,
              ),
            )
          : inner,
    );
  }

  Widget _buildSegment() {
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isPlaying = state.sourceId == widget.sourceId &&
            state.status == LessonAudioStatus.playing;

        final bgColor = isPlaying
            ? AppColors.primaryColor.withOpacity(0.10)
            : widget.highlighted
                ? Colors.white
                : const Color(0xFFF3F3F3);
        final labelColor =
            widget.highlighted ? AppColors.primaryColor : AppColors.copBlue;

        final inner = AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: null,
            boxShadow: widget.showShadow && widget.highlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: labelColor,
              ),
            ),
          ),
        );

        final half = widget.dottedStrokeWidth / 2;

        return GestureDetector(
          onTap: widget.audioUrl.isEmpty
              ? null
              : () => controller.playUrl(
                    widget.audioUrl,
                    sourceId: widget.sourceId,
                  ),
          child: widget.highlighted
              ? CustomPaint(
                  painter: LessonDottedBorderPainter(
                    color: _lessonDottedBorderColor,
                    borderRadius: widget.borderRadius + half,
                    dotSize: widget.dottedDotSize,
                    dotGap: widget.dottedDotGap,
                    strokeWidth: widget.dottedStrokeWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(half),
                    child: inner,
                  ),
                )
              : inner,
        );
      },
    );
  }

  Widget _buildSlot() {
    switch (widget.slotState) {
      case PhonemeSlotState.given:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              color: Colors.white,
            ),
          ),
        );

      case PhonemeSlotState.emptyDotted:
        final halfSlot = widget.dottedStrokeWidth / 2;
        return GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: LessonDottedBorderPainter(
              color: _lessonDottedBorderColor,
              strokeWidth: widget.dottedStrokeWidth,
              dotSize: widget.dottedDotSize,
              dotGap: widget.dottedDotGap,
              borderRadius: widget.borderRadius + halfSlot,
            ),
            child: Padding(
              padding: EdgeInsets.all(halfSlot),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '_',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: widget.fontWeight,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        );

      case PhonemeSlotState.empty:
        final halfSlot = widget.dottedStrokeWidth / 2;
        return GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: LessonDottedBorderPainter(
              color: _lessonDottedBorderColor,
              strokeWidth: widget.dottedStrokeWidth,
              dotSize: widget.dottedDotSize,
              dotGap: widget.dottedDotGap,
              borderRadius: widget.borderRadius + halfSlot,
            ),
            child: Padding(
              padding: EdgeInsets.all(halfSlot),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '_',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: widget.fontWeight,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        );

      case PhonemeSlotState.filled:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFFAEDE6),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.7),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              color: AppColors.primaryColor,
            ),
          ),
        );

      case PhonemeSlotState.filledError:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: AppColors.errorColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              color: AppColors.errorColor,
            ),
          ),
        );
    }
  }
}
