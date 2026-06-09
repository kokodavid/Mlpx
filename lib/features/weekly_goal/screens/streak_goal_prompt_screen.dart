import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';

class StreakGoalPromptScreen extends StatelessWidget {
  final String nextLessonId;

  const StreakGoalPromptScreen({
    super.key,
    required this.nextLessonId,
  });

  void _skip(BuildContext context) {
    context.push(
      '/lesson-attempt',
      extra: {'lessonId': nextLessonId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _skip(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8E8E8E),
                    backgroundColor: const Color(0xFFF9F9F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                '🔥',
                style: TextStyle(fontSize: 92, height: 1),
              ),
              const SizedBox(height: 10),
              const Text(
                '1',
                style: TextStyle(
                  color: AppColors.copBlue,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'day streak!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.copBlue,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 250,
                child: Text(
                  'Finish a lesson each day to keep your streak going',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/weekly-goal'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set streak goal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
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
