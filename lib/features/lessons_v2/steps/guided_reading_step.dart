import 'package:flutter/material.dart';
import '../models/lesson_models.dart';

class GuidedReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const GuidedReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<GuidedReadingStep> createState() => _GuidedReadingStepState();
}

class _GuidedReadingStepState extends State<GuidedReadingStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Guided Reading';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Guided reading activity — coming soon'),
        ],
      ),
    );
  }
}
