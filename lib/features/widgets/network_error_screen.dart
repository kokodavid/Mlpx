import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';

class NetworkErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;
  final bool showDownloadsAction;

  const NetworkErrorScreen({
    super.key,
    this.onRetry,
    this.message,
    this.showDownloadsAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: AppColors.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "You're offline",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.copBlue,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Check your internet connection. You can still watch your downloaded lessons.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (showDownloadsAction)
                  OutlinedButton(
                    onPressed: () => context.push('/downloaded-lessons'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                    ),
                    child: const Text('View downloads'),
                  ),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool isNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout') ||
      message.contains('timed out') ||
      message.contains('unreachable');
}
