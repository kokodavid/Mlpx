import 'package:flutter/material.dart';


// DateGreetingWidget
// Shows the current date and a time-appropriate greeting (centered row).

class DateGreetingWidget extends StatelessWidget {
  const DateGreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          dateStr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}