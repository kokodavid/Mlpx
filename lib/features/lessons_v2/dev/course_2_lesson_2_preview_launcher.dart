import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/dev/course_2_lesson_2_preview_screen.dart';
import 'package:milpress/utils/app_colors.dart';

class Course2Lesson2PreviewLauncherScreen extends StatefulWidget {
  const Course2Lesson2PreviewLauncherScreen({super.key});

  @override
  State<Course2Lesson2PreviewLauncherScreen> createState() =>
      _Course2Lesson2PreviewLauncherScreenState();
}

class _Course2Lesson2PreviewLauncherScreenState
    extends State<Course2Lesson2PreviewLauncherScreen> {
  int _selectedStepIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openPreviewAtStep(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Course2Lesson2PreviewScreen(
          key: ValueKey(index),
          initialStepIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = course2Lesson2PreviewLesson.steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Preview Launcher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Use this dev screen to preview the Course 2 Lesson 2 step flow.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'Jump to a specific step below before opening the preview:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final title = (step.config['title'] as String?)?.isNotEmpty == true
                        ? step.config['title'] as String
                        : step.type.name.replaceAll(RegExp(r'([A-Z])'), ' ').toUpperCase();
                    final isSelected = index == _selectedStepIndex;

                    return Material(
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: isSelected ? 4 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedStepIndex = index;
                          });
                          _openPreviewAtStep(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openPreviewAtStep(_selectedStepIndex),
              child: Text('Open Preview at Step ${_selectedStepIndex + 1}'),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can also use this screen as a reusable dev entry point for testing lesson steps.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
