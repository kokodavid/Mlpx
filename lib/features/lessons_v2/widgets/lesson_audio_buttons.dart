import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../providers/lesson_audio_providers.dart';
import '../services/lesson_audio_controller.dart';

class LessonAudioInlineButton extends ConsumerWidget {
  final String sourceId;
  final String url;
  final String? label;
  final Color? backgroundColor;
  final Color? iconColor; // Optional custom icon color
  final bool isCircular;
  final double? buttonSize;
  final IconData? defaultIcon;

  const LessonAudioInlineButton({
    super.key,
    required this.sourceId,
    required this.url,
    this.label,
    this.backgroundColor,
    this.iconColor,
    this.isCircular = false,
    this.buttonSize,
    this.defaultIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(lessonAudioControllerProvider);
    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isActive = state.sourceId == sourceId;
        final isLoading =
            isActive && state.status == LessonAudioStatus.loading;
        final isPlaying =
            isActive && state.status == LessonAudioStatus.playing;
        final iconData = isPlaying
            ? Icons.pause
            : (defaultIcon ?? Icons.volume_up);

        final controlSize = buttonSize ?? (isCircular ? 52.0 : 50.0);

        return GestureDetector(
          onTap: url.isEmpty
              ? () {
                  debugPrint(
                      'LessonAudioInlineButton: empty url for $sourceId');
                }
              : () => controller.playUrl(url, sourceId: sourceId),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: controlSize,
                height: controlSize,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.primaryColor
                      : (backgroundColor ?? Colors.grey[200]),
                  borderRadius: BorderRadius.circular(isCircular ? 999 : 10),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isPlaying
                                  ? Colors.white
                                  : (iconColor ?? AppColors.primaryColor),
                            ),
                          ),
                        )
                      : Icon(
                          iconData,
                          color: isPlaying
                              ? Colors.white
                              : (iconColor ?? AppColors.primaryColor),
                          size: 24,
                        ),
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class LessonAudioCardButton extends ConsumerStatefulWidget {
  final String sourceId;
  final String url;
  final Map<String, String>? speedUrls;
  final String label;

  const LessonAudioCardButton({
    super.key,
    required this.sourceId,
    required this.url,
    this.speedUrls,
    this.label = 'Tap to hear the sound',
  });

  @override
  ConsumerState<LessonAudioCardButton> createState() =>
      _LessonAudioCardButtonState();
}

class _LessonAudioCardButtonState
    extends ConsumerState<LessonAudioCardButton> {
  late String _selectedSpeed;

  @override
  void initState() {
    super.initState();
    // Define the desired order of speeds
    final desiredOrder = ['0.5x', '1x', '1.5x'];
    final availableSpeeds = widget.speedUrls?.keys.toList() ?? const [];

    // Find the first speed that exists in the desired order
    _selectedSpeed = desiredOrder.firstWhere(
          (speed) => availableSpeeds.contains(speed),
      orElse: () => availableSpeeds.isNotEmpty ? availableSpeeds.first : '1x',
    );
  }

  String get _selectedUrl {
    final speedUrls = widget.speedUrls;
    if (speedUrls == null || speedUrls.isEmpty) {
      return widget.url;
    }
    return speedUrls[_selectedSpeed] ?? widget.url;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(lessonAudioControllerProvider);
    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isActive = state.sourceId == widget.sourceId;
        final isLoading =
            isActive && state.status == LessonAudioStatus.loading;
        final isPlaying =
            isActive && state.status == LessonAudioStatus.playing;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _selectedUrl.isEmpty
                    ? () {
                  debugPrint(
                      'LessonAudioCardButton: empty url for ${widget.sourceId}');
                }
                    : () => controller.playUrl(
                  _selectedUrl,
                  sourceId: widget.sourceId,
                ),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                  ),
                ),
              ],
              if (widget.speedUrls != null &&
                  widget.speedUrls!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['0.5x', '1x', '1.5x']
                      .where((speed) => widget.speedUrls!.containsKey(speed))
                      .map((speed) {
                    final isSelected = speed == _selectedSpeed;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSpeed = speed;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.borderColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              speed,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}