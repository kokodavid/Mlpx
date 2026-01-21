import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../providers/lesson_audio_providers.dart';
import '../services/lesson_audio_controller.dart';

class LessonAudioInlineButton extends ConsumerWidget {
  final String sourceId;
  final String url;
  final String? label;

  const LessonAudioInlineButton({
    super.key,
    required this.sourceId,
    required this.url,
    this.label,
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
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.volume_up,
                        color: Colors.white,
                        size: 20,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
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
                  width: 56,
                  height: 56,
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
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
              ),
              // Inside the build method, replace the speed buttons section with:
              if (widget.speedUrls != null &&
                  widget.speedUrls!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['0.5x', '1x', '1.5x']
                      .where((speed) => widget.speedUrls!.containsKey(speed))
                      .map((speed) {
                    final isSelected = speed == _selectedSpeed;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSpeed = speed;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.borderColor,
                              ),
                            ),
                            const SizedBox(height: 8),
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
