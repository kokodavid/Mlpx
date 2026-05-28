import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_v2_download_provider.dart';

class DownloadedLessonsScreen extends ConsumerWidget {
  const DownloadedLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedLessonsAsync = ref.watch(downloadedLessonsV2Provider);

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
              const SizedBox(height: 22),
              const _SearchLessonField(),
              const SizedBox(height: 8),
              Expanded(
                child: downloadedLessonsAsync.when(
                  data: (lessons) {
                    final items = lessons
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
                ),
              ),
            ],
          ),
        ),
      ),
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
    }
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
                Icons.chevron_left,
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
  const _SearchLessonField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF101010), size: 22),
          SizedBox(width: 10),
          Text(
            'Search Lesson',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
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
