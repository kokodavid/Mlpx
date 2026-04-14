import 'package:flutter/material.dart';
import '../models/lesson_models.dart';

class SoundPresenceCheckStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SoundPresenceCheckStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SoundPresenceCheckStep> createState() => _SoundPresenceCheckStepState();
}

class _SoundPresenceCheckStepState extends State<SoundPresenceCheckStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.step.config['title'] as String? ?? 'Sound Presence Check';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Sound presence check activity — coming soon'),
        ],
      ),
    );
  }
}
