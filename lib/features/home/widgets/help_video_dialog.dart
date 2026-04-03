import 'package:flutter/material.dart';
import 'package:milpress/features/lesson/lesson_widgets/video_player_widget.dart';

class HelpVideoDialog extends StatelessWidget {
  final String? videoUrl;

  const HelpVideoDialog({Key? key, this.videoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final url = videoUrl ?? '';
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
            if (url.isNotEmpty)
              VideoPlayerWidget(
                videoUrl: url,
                height: 200,
                borderRadius: 12,
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: Text('Video not available')),
              ),
          ],
        ),
      ),
    );
  }
}
