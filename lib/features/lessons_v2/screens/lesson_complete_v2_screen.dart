import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/utils/confirm_go_home.dart';
import '../providers/lesson_providers.dart' as lessons_v2;
import '../../course/providers/module_provider.dart';

class LessonCompleteV2Screen extends ConsumerWidget {
  final String lessonId;
  final String moduleId;
  final String lessonTitle;
  final String? timeRemainingLabel;

  const LessonCompleteV2Screen({
    super.key,
    required this.lessonId,
    required this.moduleId,
    required this.lessonTitle,
    this.timeRemainingLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleLessonsAsync =
        ref.watch(lessons_v2.moduleLessonsProvider(moduleId));
    final moduleLessons = moduleLessonsAsync.value ?? const [];
    final currentIndex =
        moduleLessons.indexWhere((lesson) => lesson.id == lessonId);
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    final totalLessons = moduleLessons.isNotEmpty ? moduleLessons.length : 1;
    final progressLabel = '${safeIndex + 1} of $totalLessons LESSON';
    final nextLesson =
        (safeIndex + 1 < moduleLessons.length) ? moduleLessons[safeIndex + 1] : null;
    final hasNext = nextLesson != null;
    final moduleAsync = ref.watch(moduleFromSupabaseProvider(moduleId));
    final courseId = moduleAsync.value?.module.courseId ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: _CircleIconButton(
              icon: Icons.close,
              onPressed: () => confirmGoHome(context, courseId: courseId),
            ),
          ),
        ),
        actions: [
          _CircleIconButton(
            icon: Icons.volume_up_rounded,
            filled: true,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.help_outline_rounded,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
        centerTitle: true,
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Completed card ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    // COMPLETED badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.correctAnswerColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.correctAnswerColor,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.correctAnswerColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lessonTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.copBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/lesson-attempt',
                        extra: {'lessonId': lessonId},
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text(
                        'Review Lesson',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Progress label + motivational text ──────────────────
              Text(
                progressLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.correctAnswerColor,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are almost there',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.copBlue,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Next lesson / Finish module CTA ─────────────────────
              GestureDetector(
                onTap: hasNext
                    ? () => context.push(
                          '/lesson-attempt',
                          extra: {'lessonId': nextLesson!.id},
                        )
                    : courseId.isEmpty
                        ? null
                        : () => context.go('/course/$courseId'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: hasNext
                        ? AppColors.primaryColor
                        : AppColors.correctAnswerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasNext ? 'NEXT LESSON' : 'FINISH MODULE',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hasNext ? nextLesson!.title : lessonTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable circle icon button ──────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _CircleIconButton({
    required this.icon,
    this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryColor.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(color: AppColors.lightGrey, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? AppColors.primaryColor : AppColors.copBlue,
        ),
      ),
    );
  }
}