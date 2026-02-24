import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/providers/auth_provider.dart';


// HomeHeaderWidget
// Displays the user avatar (taps to /profile) and the decorative flame icon.

class HomeHeaderWidget extends ConsumerWidget {
  final AsyncValue profileAsync;

  const HomeHeaderWidget({super.key, required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final userName = authState.isGuestUser
        ? 'Guest'
        : profileAsync.when(
      data: (profile) => profile?.firstName ?? '',
      loading: () => '',
      error: (_, __) => '',
    );

    final profileImageUrl = authState.isGuestUser
        ? null
        : profileAsync.when(
      data: (profile) => profile?.avatarUrl,
      loading: () => null,
      error: (_, __) => null,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : (userName == 'Guest'
                  ? const AssetImage('assets/turtle.png') as ImageProvider
                  : null),
              child: profileImageUrl == null && userName != 'Guest'
                  ? Text(
                userName.isNotEmpty
                    ? userName.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
          ),

          // Decorative flame icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFEE4D8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFE8844A),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}