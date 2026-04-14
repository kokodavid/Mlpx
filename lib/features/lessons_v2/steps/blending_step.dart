import 'package:flutter/material.dart';
import '../models/lesson_models.dart';

class BlendingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const BlendingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<BlendingStep> createState() => _BlendingStepState();
}

class _BlendingStepState extends State<BlendingStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Blending';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Blending activity — coming soon'),
        ],
      ),
    );
  }
}
