import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/lesson/providers/lesson_download_provider.dart';
import 'package:milpress/features/course/providers/module_provider.dart';

class DownloadedLessonsScreen extends ConsumerWidget {
  const DownloadedLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedLessonsAsync = ref.watch(downloadedLessonIdsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Downloaded Lessons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: downloadedLessonsAsync.when(
        data: (lessonIds) {
          if (lessonIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_done,
                    size: 64,
                    color: Color(0xFF4A90E2),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No downloaded lessons',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF232B3A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Download lessons to access them offline',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessonIds.length,
            itemBuilder: (context, index) {
              final lessonId = lessonIds[index];
              return _DownloadedLessonCard(lessonId: lessonId);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading downloaded lessons',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232B3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadedLessonCard extends ConsumerWidget {
  final String lessonId;

  const _DownloadedLessonCard({required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineLessonAsync = ref.watch(offlineLessonProvider(lessonId));
    final onlineLessonAsync = ref.watch(lessonFromSupabaseProvider(lessonId));

    return offlineLessonAsync.when(
      data: (offlineLesson) {
        return onlineLessonAsync.when(
          data: (onlineLesson) {
            final lesson = offlineLesson ?? onlineLesson;
            final hasOffline = offlineLesson != null;
            if (lesson == null) {
              return _buildErrorCard('Lesson not found');
            }

            return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_done,
                color: Color(0xFF4A90E2),
                size: 28,
              ),
            ),
            title: Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232B3A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${lesson.durationMinutes} min • ${lesson.quizzes.length} quiz${lesson.quizzes.length == 1 ? '' : 'es'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) async {
                switch (value) {
                  case 'view':
                    // Navigate to lesson screen
                    if (hasOffline) {
                      context.push('/offline-lesson/${lesson.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offline data missing. Re-download the lesson.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    break;
                  case 'remove':
                    // Show confirmation dialog
                    final shouldRemove = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Download'),
                        content: Text('Are you sure you want to remove "${lesson.title}" from offline storage?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldRemove == true) {
                      await ref.read(lessonDownloadProvider(lesson.id).notifier).removeDownload();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${lesson.title} removed from offline storage'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('View Lesson'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Download', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigate to lesson screen
              if (hasOffline) {
                context.push('/offline-lesson/${lesson.id}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline data missing. Re-download the lesson.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => _buildErrorCard('Error loading lesson'),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    height: 16,
                    child: LinearProgressIndicator(),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    height: 12,
                    child: LinearProgressIndicator(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => _buildErrorCard('Error loading lesson'),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF232B3A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lesson ID: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  lessonId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
