import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:milpress/services/data_clear_service.dart';

class MenuItemsWidget extends ConsumerWidget {
  const MenuItemsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.bookmark_outline,
            title: 'Bookmarks',
            subtitle: 'Your bookmarked lessons',
            onTap: () => context.push('/bookmarks'),
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Icons.history,
            title: 'Learning History',
            subtitle: 'View your progress',
            onTap: () => context.push('/lesson-history'),
          ),
          _buildDivider(),
          // _buildMenuItem(
          //   context: context,
          //   icon: Icons.notifications_outlined,
          //   title: 'Notifications',
          //   subtitle: 'Manage your notifications',
          //   onTap: () {
          //     // TODO: Navigate to notifications settings
          //   },
          // ),
          // // _buildDivider(),
          // _buildMenuItem(
          //   context: context,
          //   icon: Icons.settings_outlined,
          //   title: 'Settings',
          //   subtitle: 'App preferences',
          //   onTap: () {
          //     // TODO: Navigate to settings
          //   },
          // ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Icons.delete_outline,
            title: 'Clear All Data',
            subtitle: 'Reset app to factory settings',
            onTap: () => _showClearDataDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App information',
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will delete all your local data including:\n'
            '• Assessment results\n'
            '• Course progress\n'
            '• Bookmarks\n'
            '• Learning history\n'
            '• App settings\n\n'
            'This action cannot be undone. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _clearAllData(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext loadingContext) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Clearing all data...'),
              ],
            ),
          );
        },
      );

      // Clear all persistent data using the service
      await DataClearService.clearAllData();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to welcome screen
      if (context.mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.copBlue,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textColor,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.borderColor,
    );
  }
}