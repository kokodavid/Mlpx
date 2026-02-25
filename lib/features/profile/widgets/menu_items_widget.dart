import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import 'package:milpress/services/data_clear_service.dart';

class MenuItemsWidget extends ConsumerWidget {
  const MenuItemsWidget({super.key});

  static void showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear All Data'),
          content: const Text(
            'This will delete all your local data including:\n'
                '• Assessment results\n'
                '• Course progress\n'
                '• Bookmarks\n'
                '• Learning history\n'
                '• App settings\n\n'
                'This action cannot be undone. Are you sure?',
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _clearAllData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );

      await DataClearService.clearAllData();

      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/welcome');
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        //  Card : Profile Info
        _buildCard(
          children: [
            _buildMenuItem(
              context: context,
              icon: Icons.person,
              title: 'Profile info',
              subtitle: 'All you profile information',
              onTap: () => context.push('/edit-profile'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Card : Bookmark + History
        _buildCard(
          children: [
            _buildMenuItem(
              context: context,
              icon: Icons.bookmark,
              title: 'Bookmark',
              subtitle: 'Find saved lesson(s) here',
              badge: const _Badge(count: 0),
              onTap: () => context.push('/bookmarks'),
            ),
            const Divider(height: 1, indent: 52, endIndent: 0),
            _buildMenuItem(
              context: context,
              icon: Icons.history,
              title: 'History',
              subtitle: 'See attempted lessons',
              badge: const _Badge(count: 0),
              onTap: () => context.push('/lesson-history'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Card : About Milpress
        _buildCard(
          children: [
            _buildMenuItem(
              context: context,
              icon: null,
              title: 'About Milpress',
              subtitle: '',
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
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
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Light grey container, solid copBlue filled icon
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.copBlue, size: 22),
              ),
              const SizedBox(width: 12),
            ],

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.copBlue,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (badge != null) ...[badge, const SizedBox(width: 8)],

            const Icon(Icons.chevron_right,
                color: AppColors.textColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}