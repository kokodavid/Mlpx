import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milpress/features/reviews/models/lesson_completion_model.dart';
import 'package:milpress/features/reviews/providers/lesson_history_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:go_router/go_router.dart';

class LessonHistoryScreen extends ConsumerStatefulWidget {
  const LessonHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LessonHistoryScreen> createState() =>
      _LessonHistoryScreenState();
}

class _LessonHistoryScreenState extends ConsumerState<LessonHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonHistoryAsync = ref.watch(lessonHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.copBlue),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lesson History',
          style: TextStyle(
            color: AppColors.copBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: lessonHistoryAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return _buildEmptyState();
          }

          // Filter by search query
          final filtered = _searchQuery.isEmpty
              ? lessons
              : lessons.where((l) {
            final title = (l.lessonTitle ?? '').toLowerCase();
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search History',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                  child: Text(
                    'No results found.',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _LessonHistoryCard(
                        lesson: filtered[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layered circle icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.12),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withOpacity(0.18),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryColor,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No completed lesson yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.copBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'There are currently no completed lessons\nto display.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// History card
class _LessonHistoryCard extends StatelessWidget {
  final LessonCompletionModel lesson;
  const _LessonHistoryCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final dateStr = lesson.completedAt != null
        ? 'Time: ${DateFormat('MMM d, yyyy . h:mm a').format(lesson.completedAt!)}'
        : '';

    // Label shown above the lesson title — "Lesson" or "Assessment"
    final typeLabel =
    lesson.lessonTitle?.toLowerCase().contains('assessment') == true
        ? 'Assessment'
        : 'Lesson';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type label row with green dot
            Row(
              children: [
                const Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Lesson title
            Text(
              lesson.lessonTitle ?? 'Lesson',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Date/time
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
