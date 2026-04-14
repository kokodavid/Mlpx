import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';

class SentenceReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SentenceReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SentenceReadingStep> createState() => _SentenceReadingStepState();
}

class _SentenceReadingStepState extends State<SentenceReadingStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Sentence Reading';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Sentence reading activity — coming soon'),
        ],
      ),
    );
  }
}
