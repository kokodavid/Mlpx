import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';

class MissingLettersStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MissingLettersStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MissingLettersStep> createState() => _MissingLettersStepState();
}

class _MissingLettersStepState extends State<MissingLettersStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Missing Letters';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Missing letters activity — coming soon'),
        ],
      ),
    );
  }
}
