import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milpress/features/reviews/providers/lesson_history_provider.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:go_router/go_router.dart';

class LessonHistoryScreen extends ConsumerWidget {
  const LessonHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonHistoryAsync = ref.watch(lessonHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson History'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: lessonHistoryAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(
              child: Text('No completed lessons yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _LessonHistoryCard(lesson: lesson);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LessonHistoryCard extends StatelessWidget {
  final LessonProgressModel lesson;
  const _LessonHistoryCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final dateStr = lesson.completedAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(lesson.completedAt!)
        : 'Unknown date';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (lesson.lessonId.isEmpty) return;
        context.push('/lesson/${lesson.lessonId}', extra: {
          'courseContext': {
            'courseId': '',
            'moduleId': lesson.moduleId,
            'isFromBookmark': true,
          },
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(
                lesson.status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: lesson.status == 'completed' ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lesson.lessonTitle ?? 'Lesson',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF232B3A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                lesson.status == 'completed' ? 'Completed' : 'Incomplete',
                style: TextStyle(
                  fontSize: 12,
                  color: lesson.status == 'completed' ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lesson.quizScore != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.assessment, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Score: ${lesson.quizScore}/${lesson.quizTotalQuestions ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ],
          ),
          if (lesson.completedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Completed: $dateStr',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }
} 
