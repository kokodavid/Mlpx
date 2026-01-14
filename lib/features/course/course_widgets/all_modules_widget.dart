import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../course_models/complete_course_model.dart';
import 'package:milpress/utils/app_colors.dart';
import '../providers/module_provider.dart';

class AllModulesWidget extends ConsumerStatefulWidget {
  final List<ModuleWithLessons> modules;
  final Map<String, bool> completedModules; // moduleId -> completed
  final String? ongoingModuleId;

  const AllModulesWidget({
    Key? key,
    required this.modules,
    required this.completedModules,
    this.ongoingModuleId,
  }) : super(key: key);

  @override
  ConsumerState<AllModulesWidget> createState() => _AllModulesWidgetState();
}

class _AllModulesWidgetState extends ConsumerState<AllModulesWidget> {
  List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(widget.modules.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.modules.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            'All Modules',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            final isCompleted = widget.completedModules[module.module.id] ?? false;
            final isOngoing = widget.ongoingModuleId == module.module.id;
            final expanded = _expanded[index];
            final completedLessonIdsAsync = ref.watch(
              completedLessonIdsProvider(module.module.id),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded[index] = !_expanded[index];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Container(
                                //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                //   decoration: BoxDecoration(
                                //     color: Colors.grey[300],
                                //     borderRadius: BorderRadius.circular(10),
                                //   ),
                                //   child: Text(
                                //     'Module ${index + 1}',
                                //     style: const TextStyle(fontSize: 13, color: Colors.black54),
                                //   ),
                                // ),
                                const SizedBox(height: 8),
                                Text(
                                  module.module.description,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF232B3A),
                                  ),
                                ),
                                if (isCompleted)
                                  const Text('Lesson completed', style: TextStyle(color: Colors.green, fontSize: 15))
                                else if (isOngoing)
                                  const Text('Lessons ongoing', style: TextStyle(color: Colors.orange, fontSize: 15)),
                              ],
                            ),
                            const Spacer(),
                            if (isCompleted)
                              const Icon(Icons.check_circle, color: Colors.green, size: 24)
                            else if (isOngoing)
                              const Icon(Icons.timer, color: Colors.orange, size: 24),
                            // Chevron icon for expand/collapse
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more, size: 28, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                      if (expanded)
                        Container(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(module.lessons.length, (lessonIdx) {
                                final lesson = module.lessons[lessonIdx];
                                final lessonCompleted = completedLessonIdsAsync.maybeWhen(
                                  data: (ids) => ids.contains(lesson.id),
                                  orElse: () => false,
                                );
                                
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            lessonCompleted ? Icons.check_circle : Icons.circle_outlined,
                                            size: 20,
                                            color: lessonCompleted ? Colors.green : AppColors.textColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              lesson.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: lessonCompleted ? Colors.green : AppColors.textColor,
                                              ),
                                            ),
                                          ),
                                          if (lessonCompleted)
                                            const Icon(Icons.check, color: Colors.green, size: 16),
                                        ],
                                      ),
                                    ),
                                    if (lessonIdx < module.lessons.length - 1)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Divider(height: 1, color: Colors.grey[300]),
                                      ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
