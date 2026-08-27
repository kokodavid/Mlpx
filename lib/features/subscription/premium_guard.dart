import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/providers/auth_provider.dart';

import 'paywall_screen.dart';

// =============================================================================
// PremiumGuard
//
// Wraps any widget tree that should only be accessible to premium / sponsored
// users.  Usage:
//
//   PremiumGuard(
//     child: LessonDetailScreen(lesson: lesson),
//   )
//
// Or inline as a tap handler guard:
//
//   PremiumGuard.gate(
//     context: context,
//     ref: ref,
//     onGranted: () => Navigator.push(...),
//   );
// =============================================================================
class PremiumGuard extends ConsumerWidget {
  /// The content to show when the user has premium access.
  final Widget child;

  /// Optional widget to show in place of [child] when access is denied.
  /// Defaults to showing a lock overlay on top of a blurred version of [child].
  final Widget? lockedPlaceholder;

  const PremiumGuard({
    super.key,
    required this.child,
    this.lockedPlaceholder,
  });

  // ---------------------------------------------------------------------------
  // Static helper — gate a callback without wrapping a widget tree
  // ---------------------------------------------------------------------------
  /// Returns true if the user has premium access.
  /// If not, shows the paywall and returns false.
  static bool gate({
    required BuildContext context,
    required WidgetRef ref,
    VoidCallback? onGranted,
  }) {
    final hasAccess = ref.read(hasPremiumAccessProvider);
    if (hasAccess) {
      onGranted?.call();
      return true;
    }
    showPaywall(context);
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(hasPremiumAccessProvider);

    if (hasAccess) return child;

    if (lockedPlaceholder != null) return lockedPlaceholder!;

    // Default locked state: show child behind a semi-transparent overlay
    // with a lock icon and "Unlock" button.
    return Stack(
      children: [
        // Blurred / dimmed child
        IgnorePointer(
          child: Opacity(opacity: 0.35, child: child),
        ),
        // Lock overlay
        Positioned.fill(
          child: _LockOverlay(
            onUnlock: () => showPaywall(context),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _LockOverlay — shown on top of gated content
// =============================================================================
class _LockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockOverlay({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 28,
                color: Color(0xFFE85D04), // AppColors.primaryColor
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Premium content',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF142C44), // AppColors.copBlue
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Unlock',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
