import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';

class WordReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const WordReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<WordReadingStep> createState() => _WordReadingStepState();
}

class _WordReadingStepState extends State<WordReadingStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Word Reading';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Word reading activity — coming soon'),
        ],
      ),
    );
  }
}
