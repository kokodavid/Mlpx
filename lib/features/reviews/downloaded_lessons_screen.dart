import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/course/providers/course_download_provider.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_v2_download_provider.dart';
import 'package:milpress/features/reviews/providers/downloaded_courses_provider.dart';
import 'package:milpress/utils/app_colors.dart';

enum _DownloadedLessonsTab { all, course }

class DownloadedLessonsScreen extends ConsumerStatefulWidget {
  const DownloadedLessonsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DownloadedLessonsScreen> createState() =>
      _DownloadedLessonsScreenState();
}

class _DownloadedLessonsScreenState
    extends ConsumerState<DownloadedLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _DownloadedLessonsTab _selectedTab = _DownloadedLessonsTab.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadedLessonsAsync = ref.watch(downloadedLessonsV2Provider);
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
              _DownloadedTabs(
                selectedTab: _selectedTab,
                onChanged: (tab) => setState(() => _selectedTab = tab),
              ),
              const SizedBox(height: 16),
              _SearchLessonField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedTab == _DownloadedLessonsTab.all
                    ? _buildAllTab(downloadedLessonsAsync, query)
                    : _buildCourseTab(downloadedCoursesAsync, query),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTab(
    AsyncValue<List<LessonDefinition>> downloadedLessonsAsync,
    String query,
  ) {
    return downloadedLessonsAsync.when(
      data: (lessons) {
        final items = lessons
            .where((lesson) => lesson.title.toLowerCase().contains(query))
            .map(
              (lesson) => _DownloadedLessonUiItem(
                id: lesson.id,
                type: 'Lesson',
                title: lesson.title,
                downloadedAt: _formatDownloadedAt(
                  ref
                      .watch(
                        downloadedLessonV2TimeProvider(lesson.id),
                      )
                      .valueOrNull,
                ),
              ),
            )
            .toList(growable: false);

        if (items.isEmpty) {
          return const _EmptyDownloadsState();
        }

        return _DownloadedLessonsList(
          items: items,
          onRemove: (lessonId) => _removeDownload(
            context,
            ref,
            lessonId,
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const _EmptyDownloadsState(),
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

  String _formatDownloadedAt(DateTime? value) {
    if (value == null) {
      return 'Time: Unknown';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final month = months[value.month - 1];
    return 'Time: $month ${value.day}, ${value.year} . $hour:$minute $period';
  }

  Future<void> _removeDownload(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
  ) async {
    await ref
        .read(lessonV2DownloadProvider(lessonId).notifier)
        .removeDownload();
    if (context.mounted) {
      ref.invalidate(downloadedLessonsV2Provider);
      ref.invalidate(downloadedLessonsV2CountProvider);
      ref.invalidate(downloadedCoursesProvider);
    }
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

class _DownloadedLessonUiItem {
  final String id;
  final String type;
  final String title;
  final String downloadedAt;

  const _DownloadedLessonUiItem({
    required this.id,
    required this.type,
    required this.title,
    required this.downloadedAt,
  });
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

class _DownloadedTabs extends StatelessWidget {
  final _DownloadedLessonsTab selectedTab;
  final ValueChanged<_DownloadedLessonsTab> onChanged;

  const _DownloadedTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DownloadedTabButton(
          label: 'All',
          isSelected: selectedTab == _DownloadedLessonsTab.all,
          onTap: () => onChanged(_DownloadedLessonsTab.all),
        ),
        const SizedBox(width: 12),
        _DownloadedTabButton(
          label: 'Course',
          isSelected: selectedTab == _DownloadedLessonsTab.course,
          onTap: () => onChanged(_DownloadedLessonsTab.course),
        ),
      ],
    );
  }
}

class _DownloadedTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DownloadedTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.greyText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
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
                color: _courseAvatarColor(title),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _courseAvatarIcon(title),
                color:AppColors.primaryColor,
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

  Color _courseAvatarColor(String title) {
    const colors = [
      Color(0xFFFFE7E7),
      Color(0xFFE8FFF4),
      Color(0xFFEAF4FF),
      Color(0xFFFFF5D8),
      Color(0xFFF3E8FF),
    ];
    return colors[title.hashCode.abs() % colors.length];
  }

  IconData _courseAvatarIcon(String title) {
    const icons = [
      Icons.school,
      Icons.menu_book,
      Icons.edit,
      Icons.savings,
      Icons.schedule,
    ];
    return icons[title.hashCode.abs() % icons.length];
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
                    Icons.shopping_bag,
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

class _DownloadedLessonsList extends StatelessWidget {
  final List<_DownloadedLessonUiItem> items;
  final ValueChanged<String> onRemove;

  const _DownloadedLessonsList({
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _DownloadedLessonCard(
          item: items[index],
          onRemove: () => onRemove(items[index].id),
          onTap: () {
            context.push(
              '/lesson-attempt',
              extra: {
                'lessonId': items[index].id,
                'isReattempt': true,
              },
            );
          },
        );
      },
    );
  }
}

class _DownloadedLessonCard extends StatelessWidget {
  final _DownloadedLessonUiItem item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _DownloadedLessonCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF88C678).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF6BB255),
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.type,
                        style: const TextStyle(
                          color: Color(0xFF6D6D6D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Downloaded: ${item.title}',
                    style: const TextStyle(
                      color: Color(0xFF5EAB45),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.downloadedAt,
                    style: const TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.errorColor,
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
