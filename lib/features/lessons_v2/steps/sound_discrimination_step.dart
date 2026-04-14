import 'package:flutter/material.dart';
import '../models/lesson_models.dart';

class SoundDiscriminationStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SoundDiscriminationStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SoundDiscriminationStep> createState() =>
      _SoundDiscriminationStepState();
}

class _SoundDiscriminationStepState extends State<SoundDiscriminationStep> {
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
        widget.step.config['title'] as String? ?? 'Sound Discrimination';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Sound discrimination activity — coming soon'),
        ],
      ),
    );
  }
}
