import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/course/providers/course_download_provider.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_v2_download_provider.dart';
import 'package:milpress/features/reviews/providers/downloaded_courses_provider.dart';
import 'package:milpress/utils/app_colors.dart';

class DownloadedLessonsScreen extends ConsumerStatefulWidget {
  const DownloadedLessonsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DownloadedLessonsScreen> createState() =>
      _DownloadedLessonsScreenState();
}

class _DownloadedLessonsScreenState
    extends ConsumerState<DownloadedLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadedCoursesAsync = ref.watch(downloadedCoursesProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              _DownloadedLessonsHeader(onBack: () => context.pop()),
              const SizedBox(height: 20),
              _SearchLessonField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildCourseTab(downloadedCoursesAsync, query),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseTab(
    AsyncValue<List<DownloadedCourseItem>> downloadedCoursesAsync,
    String query,
  ) {
    return downloadedCoursesAsync.when(
      data: (courses) {
        final filtered = courses
            .where(
              (item) =>
                  item.course.course.title.toLowerCase().contains(query),
            )
            .toList(growable: false);

        if (filtered.isEmpty) {
          return const _EmptyDownloadsState();
        }

        return _DownloadedCoursesList(
          items: filtered,
          onDownload: (courseId) => _downloadCourse(courseId),
          onRemove: (courseId) => _removeCourseDownload(courseId),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _EmptyDownloadsState(),
    );
  }

  Future<void> _downloadCourse(String courseId) async {
    await ref.read(courseV2DownloadProvider(courseId).notifier).downloadCourse();
    if (!mounted) return;
    ref.invalidate(downloadedCoursesProvider);
    ref.invalidate(downloadedLessonsV2Provider);
  }

  Future<void> _removeCourseDownload(String courseId) async {
    await ref
        .read(courseV2DownloadProvider(courseId).notifier)
        .removeCourseDownload();
    if (!mounted) return;
    ref.invalidate(downloadedCoursesProvider);
    ref.invalidate(downloadedLessonsV2Provider);
    ref.invalidate(downloadedLessonsV2CountProvider);
  }
}

class _DownloadedLessonsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DownloadedLessonsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade200),
              ),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ),
        const Text(
          'Downloaded Lesson',
          style: TextStyle(
            color: Color(0xFF101010),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SearchLessonField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchLessonField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF101010), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search Lesson',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: Color(0xFF303030),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadedCoursesList extends StatelessWidget {
  final List<DownloadedCourseItem> items;
  final ValueChanged<String> onDownload;
  final ValueChanged<String> onRemove;

  const _DownloadedCoursesList({
    required this.items,
    required this.onDownload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DownloadedCourseCard(
          item: item,
          onTap: () => context.push('/course/${item.course.course.id}'),
          onAction: () {
            if (item.isStored) {
              onRemove(item.course.course.id);
            } else {
              onDownload(item.course.course.id);
            }
          },
        );
      },
    );
  }
}

class _DownloadedCourseCard extends StatelessWidget {
  final DownloadedCourseItem item;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _DownloadedCourseCard({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.course.course.title;
    final isStored = item.isStored;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF101010),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isStored ? Icons.check_circle : Icons.cloud,
                        color: isStored
                            ? AppColors.successColor
                            : AppColors.greyText,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isStored
                              ? 'Stored on device · ${_formatBytes(item.storedBytes)}'
                              : 'Available online · ${_formatBytes(item.availableBytes)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isStored
                                ? AppColors.successColor
                                : AppColors.greyText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAction,
              icon: Icon(
                isStored ? Icons.delete_outline : Icons.file_download_outlined,
                color: isStored ? AppColors.errorColor : AppColors.primaryColor,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
}

class _EmptyDownloadsState extends StatelessWidget {
  const _EmptyDownloadsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBDD),
                borderRadius: BorderRadius.circular(37),
              ),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD4B8),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFFD96C1F),
                    size: 23,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yet to see downloaded\nlessons',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101010),
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'There are currently no downloaded\nlessons to display.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6D6D6D),
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}