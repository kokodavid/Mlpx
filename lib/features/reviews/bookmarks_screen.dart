import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milpress/utils/app_colors.dart';
import 'providers/bookmark_provider.dart';
import 'models/bookmark_model.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(userBookmarksProvider);

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
          'Bookmarked Lesson',
          style: TextStyle(
            color: AppColors.copBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return _buildEmptyState();
          }
          return _buildList(context, ref, bookmarks);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Error loading bookmarks',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
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
          // Double-layered soft circle with bookmark icon
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
                  Icons.bookmark,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No bookmark lesson yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.copBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Bookmark lessons to save and review\nthem later.',
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

  // Populated list
  Widget _buildList(
      BuildContext context,
      WidgetRef ref,
      List<BookmarkModel> bookmarks,
      ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _BookmarkCard(
          bookmark: bookmark,
          onRemove: () => _removeBookmark(context, ref, bookmark),
          onTap: () => _navigateToLesson(context, bookmark),
        );
      },
    );
  }

  Future<void> _removeBookmark(
      BuildContext context,
      WidgetRef ref,
      BookmarkModel bookmark,
      ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Bookmark'),
        content: Text(
          'Are you sure you want to remove "${bookmark.lessonTitle}" from your bookmarks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      try {
        await ref.read(removeBookmarkProvider(bookmark.lessonId).future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing bookmark: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToLesson(BuildContext context, BookmarkModel bookmark) {
    context.push('/lesson/${bookmark.lessonId}', extra: {
      'courseContext': {
        'courseId': bookmark.courseId,
        'courseTitle': bookmark.courseTitle,
        'moduleId': bookmark.moduleId,
        'moduleTitle': bookmark.moduleTitle,
        'isFromBookmark': true,
      },
    });
  }
}

// Bookmark card
class _BookmarkCard extends StatelessWidget {
  final BookmarkModel bookmark;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.bookmark,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = 'Time: ${DateFormat('MMM d, yyyy . h:mm a').format(bookmark.bookmarkedAt)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Green dot + text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson name row with green dot
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bookmark.lessonTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.copBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}