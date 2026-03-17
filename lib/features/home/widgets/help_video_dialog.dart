import 'package:flutter/material.dart';
import 'package:milpress/features/lesson/lesson_widgets/video_player_widget.dart';

class HelpVideoDialog extends StatelessWidget {
  const HelpVideoDialog({Key? key}) : super(key: key);

  static const String _placeholderVideoUrl =
      'https://www.w3schools.com/html/mov_bbb.mp4'; // TODO: replace with real URL

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const VideoPlayerWidget(
              videoUrl: _placeholderVideoUrl,
              height: 200,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
