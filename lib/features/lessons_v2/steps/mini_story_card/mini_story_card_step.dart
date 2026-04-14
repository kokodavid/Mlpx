import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';

class MiniStoryCardStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MiniStoryCardStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MiniStoryCardStep> createState() => _MiniStoryCardStepState();
}

class _MiniStoryCardStepState extends State<MiniStoryCardStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Mini Story Card';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Mini story card activity — coming soon'),
        ],
      ),
    );
  }
}
