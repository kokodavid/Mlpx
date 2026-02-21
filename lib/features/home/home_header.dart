import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isGuestUser;
  final DateTime? currentDateTime;

  const HomeHeader({
    Key? key,
    required this.userName,
    required this.isGuestUser,
    this.profileImageUrl,
    this.currentDateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = currentDateTime ?? DateTime.now();
    final dateText = _formatHeaderDate(now);
    final greeting = _greetingForHour(now.hour);
    final avatarTap = isGuestUser ? null : () => context.push('/profile');
    final streakTap = isGuestUser ? null : () => context.push('/weekly-goal');
    final disabledOpacity = isGuestUser ? 0.55 : 1.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Opacity(
                opacity: disabledOpacity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('home_header_avatar_button'),
                    onTap: avatarTap,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE6E6E6),
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : (userName == 'Guest'
                                ? const AssetImage('assets/turtle.png')
                                    as ImageProvider
                                : null),
                        child: profileImageUrl == null && userName != 'Guest'
                            ? Text(
                                userName.isNotEmpty
                                    ? userName.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.copBlue,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: disabledOpacity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('home_header_streak_button'),
                    onTap: streakTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sandyLight,
                        border: Border.all(
                          color: AppColors.sandColor.withValues(alpha: 0.6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_fire_department,
                        color: AppColors.primaryColor,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              key: const Key('home_header_greeting_pill'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatHeaderDate(DateTime date) {
    const months = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
