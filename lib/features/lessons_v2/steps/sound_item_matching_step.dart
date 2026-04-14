import 'package:flutter/material.dart';
import '../models/lesson_models.dart';

class SoundItemMatchingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SoundItemMatchingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SoundItemMatchingStep> createState() => _SoundItemMatchingStepState();
}

class _SoundItemMatchingStepState extends State<SoundItemMatchingStep> {
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
        widget.step.config['title'] as String? ?? 'Sound Item Matching';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Sound item matching activity — coming soon'),
        ],
      ),
    );
  }
}
