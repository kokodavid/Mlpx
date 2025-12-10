import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/profile/providers/profile_provider.dart';
import '../providers/auth_provider.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _hasRefreshed = false;

  @override
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Manual refresh button
              ref.invalidate(profileProvider);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          // Debug: Print what we got
          debugPrint('Profile Screen - Profile data: ${profile?.toJson()}');
          debugPrint('Profile Screen - User email: ${user?.email}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  profile?.email ?? user?.email ?? 'No email',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (profile?.firstName != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${profile!.firstName} ${profile.lastName ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'User ID: ${user?.id ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
        error: (error, stack) {
          // Debug: Print the error
          debugPrint('Profile Screen - Error: $error');
          debugPrint('Profile Screen - Stack: $stack');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 20),
                Text(
                  user?.email ?? 'No email',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'Error loading profile',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(profileProvider);
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}