import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';

class CourseCard extends ConsumerWidget {
  final String title;
  final int level;
  final String levelLabel;
  final int durationMinutes;
  final int totalModules;
  final int totalLessons;
  final bool eligible;
  final bool locked;
  final String? lockMessage;
  final VoidCallback? onStart;
  final String? audioPath;
  final bool isCompleted;
  final int completedLessons;
  final double? lessonProgressValue;

  const CourseCard({
    required this.title,
    required this.level,
    this.levelLabel = 'Level',
    required this.durationMinutes,
    required this.totalModules,
    required this.totalLessons,
    this.eligible = true,
    this.locked = false,
    this.lockMessage,
    this.onStart,
    this.audioPath,
    this.isCompleted = false,
    this.completedLessons = 0,
    this.lessonProgressValue,
    Key? key,
  }) : super(key: key);

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '$hours Hours ${minutes > 0 ? "$minutes Minutes" : ""}';
    } else {
      return '$minutes Minutes';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                SizedBox(
                  height: 110,
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF2992F), width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            levelLabel,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF2992F),
                            ),
                          ),
                          Text(
                            '$level',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF2992F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232B3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDuration,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (audioPath != null)
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.grey),
                  ),
                const SizedBox(height: 16),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoPill(icon: Icons.menu_book, label: '$totalModules Modules'),
                    const SizedBox(width: 12),
                    _InfoPill(icon: Icons.menu, label: '$totalLessons Lessons'),
                  ],
                ),
                const SizedBox(height: 16),
                if (totalLessons > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: lessonProgressValue ?? (completedLessons / totalLessons),
                        backgroundColor: Colors.grey[200],
                        color: AppColors.primaryColor,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completedLessons of $totalLessons lessons completed',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: eligible ? Colors.green : Colors.grey, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      eligible
                          ? 'You are eligible to start this level'
                          : 'Not eligible yet',
                      style: TextStyle(color: eligible ? Colors.green : Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (locked && lockMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        Text(lockMessage!, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                CustomButton(
                  text: isCompleted
                      ? 'Review Level $level'
                      : 'Start Level $level',
                  onPressed: locked ? null : onStart,
                  fillColor: locked
                      ? Colors.grey
                      : isCompleted
                          ? Colors.green
                          : AppColors.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
} 