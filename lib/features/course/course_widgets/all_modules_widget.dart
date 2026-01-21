import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../course_models/complete_course_model.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart'
    as lessons_v2;

class AllModulesWidget extends ConsumerStatefulWidget {
  final List<ModuleWithLessons> modules;
  final String? ongoingModuleId;
  final String? courseId;
  final String? courseTitle;
  final int? totalModules;
  final int? totalLessons;

  const AllModulesWidget({
    Key? key,
    required this.modules,
    this.ongoingModuleId,
    this.courseId,
    this.courseTitle,
    this.totalModules,
    this.totalLessons,
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
            final expanded = _expanded[index];
            final moduleLessonsAsync = ref.watch(
              lessons_v2.moduleLessonsProvider(module.module.id),
            );
            final moduleLessons =
                moduleLessonsAsync.value ?? const <LessonDefinition>[];
            final completedLessonIdsAsync = ref.watch(
              lessons_v2.completedLessonIdsV2Provider(module.module.id),
            );
            final completedLessonIds =
                completedLessonIdsAsync.value ?? const <String>{};
            final completedLessonCount = completedLessonIds.length;
            final totalLessonCount = moduleLessons.length;
            final isCompleted = totalLessonCount > 0 &&
                completedLessonCount >= totalLessonCount;
            final isOngoing = !isCompleted &&
                (widget.ongoingModuleId == module.module.id);
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
                                const SizedBox(height: 8),
                                Text(
                                  module.module.description,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF232B3A),
                                  ),
                                ),
                                if (moduleLessonsAsync.isLoading)
                                  const Text(
                                    'Loading lessons...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  )
                                else if (totalLessonCount == 0)
                                  const Text(
                                    'No lessons available',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  )
                                else
                                  Text(
                                    '$completedLessonCount of $totalLessonCount lessons completed',
                                    style: TextStyle(
                                      color: isCompleted
                                          ? Colors.green
                                          : (isOngoing
                                              ? Colors.orange
                                              : Colors.grey),
                                      fontSize: 14,
                                    ),
                                  ),
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
                              if (moduleLessonsAsync.isLoading)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              if (!moduleLessonsAsync.isLoading &&
                                  moduleLessons.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No lessons available yet.',
                                    style: TextStyle(color: AppColors.textColor),
                                  ),
                                ),
                              ...List.generate(moduleLessons.length, (lessonIdx) {
                                final lesson = moduleLessons[lessonIdx];
                                
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (!completedLessonIds
                                            .contains(lesson.id)) {
                                          // ScaffoldMessenger.of(context)
                                          //     .showSnackBar(
                                          //   const SnackBar(
                                          //     content: Text(
                                          //         'Complete lesson for review to be available.'),
                                          //   ),
                                          // );
                                          return;
                                        }
                                        context.push(
                                          '/lesson-attempt',
                                          extra: {
                                            'lessonId': lesson.id,
                                            'isReattempt': true,
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              completedLessonIds.contains(lesson.id)
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              size: 20,
                                              color: completedLessonIds.contains(lesson.id)
                                                  ? AppColors.correctAnswerColor
                                                  : AppColors.textColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                lesson.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (lessonIdx < moduleLessons.length - 1)
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
