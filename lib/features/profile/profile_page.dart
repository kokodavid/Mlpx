import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import 'providers/profile_provider.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/menu_items_widget.dart';
import 'widgets/logout_button_widget.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

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
      body: profileAsync.when(
        data: (profile) => _buildBody(context, ref, profile),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorColor, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load profile'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(profileProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, profile) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Profile header (avatar + name + email)
                  ProfileHeaderWidget(profile: profile),

                  const SizedBox(height: 24),

                  // Menu items card
                  const MenuItemsWidget(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // Sign Out button pinned to bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: LogoutButtonWidget(
            onLogout: () => _handleLogout(ref),
          ),
        ),
      ],
    );
  }

  void _handleLogout(WidgetRef ref) async {
    try {
      await ref.read(profileProvider.notifier).signOut();
    } catch (_) {}
  }
}