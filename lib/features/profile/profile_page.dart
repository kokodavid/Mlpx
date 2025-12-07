import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import 'providers/profile_provider.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/stats_section_widget.dart';
import 'widgets/menu_items_widget.dart';
import 'widgets/logout_button_widget.dart';
import 'widgets/loading_card.dart';
import 'widgets/error_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.copBlue),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.copBlue,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header Section
              profileAsync.when(
                data: (profile) => ProfileHeaderWidget(
                  profile: profile,
                  onEditProfile: () {
                    // TODO: Navigate to edit profile screen
                  },
                ),
                loading: () => const LoadingCard(),
                error: (error, stack) => ErrorCard(
                  message: 'Failed to load profile',
                  onRetry: () => ref.refresh(profileProvider),
                ),
              ),
              const SizedBox(height: 32),
              
              // Stats Section
              statsAsync.when(
                data: (stats) => StatsSectionWidget(stats: stats),
                loading: () => const LoadingCard(),
                error: (error, stack) => ErrorCard(
                  message: 'Failed to load stats',
                  onRetry: () => ref.refresh(userStatsProvider),
                ),
              ),
              const SizedBox(height: 32),
              
              // Menu Items
              const MenuItemsWidget(),
              const SizedBox(height: 32),
              
              // Logout Button
              LogoutButtonWidget(
                onLogout: () => _handleLogout(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(WidgetRef ref) async {
    try {
      await ref.read(profileProvider.notifier).signOut();
    } catch (e) {
      // Error handling is done in the provider
    }
  }
}
