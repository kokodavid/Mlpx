import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';

class MatchingWordsStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MatchingWordsStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MatchingWordsStep> createState() => _MatchingWordsStepState();
}

class _MatchingWordsStepState extends State<MatchingWordsStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Matching Words';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Matching words activity — coming soon'),
        ],
      ),
    );
  }
}
