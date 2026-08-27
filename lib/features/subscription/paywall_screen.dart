import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';

import 'subscription_plan_model.dart';
import 'subscription_plan_service.dart';
import 'stripe_service.dart';

// =============================================================================
// PaywallScreen
//
// Usage — push directly when a free user hits premium content:
//   Navigator.of(context).push(MaterialPageRoute(
//     builder: (_) => const PaywallScreen(),
//   ));
//
// Or as a bottom sheet:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => const PaywallScreen(isModal: true),
//   );
// =============================================================================
class PaywallScreen extends ConsumerWidget {
  /// When true the screen renders as a bottom-sheet style panel (no AppBar,
  /// drag handle shown at top). When false it renders as a full page.
  final bool isModal;

  const PaywallScreen({super.key, this.isModal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(activePlansProvider);

    final body = plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(activePlansProvider)),
      data: (plans) => _PlansBody(plans: plans, isModal: isModal),
    );

    if (isModal) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.copBlue),
      ),
      body: body,
    );
  }
}

// =============================================================================
// Body — renders the plan cards
// =============================================================================
class _PlansBody extends StatefulWidget {
  final List<SubscriptionPlan> plans;
  final bool isModal;
  const _PlansBody({required this.plans, required this.isModal});

  @override
  State<_PlansBody> createState() => _PlansBodyState();
}

class _PlansBodyState extends State<_PlansBody> {
  late String _selectedPlanId;

  @override
  void initState() {
    super.initState();
    // Pre-select the highlighted plan, or the first paid one
    final highlighted = widget.plans.where((p) => p.isHighlighted).firstOrNull;
    final firstPaid   = widget.plans.where((p) => !p.isFree).firstOrNull;
    _selectedPlanId   = (highlighted ?? firstPaid ?? widget.plans.first).id;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const SizedBox(height: 8),
          const Text(
            'Unlock your full potential',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.copBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the plan that works for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 28),

          // Plan cards
          ...widget.plans.map((plan) => _PlanCard(
                plan: plan,
                isSelected: _selectedPlanId == plan.id,
                onTap: () => setState(() => _selectedPlanId = plan.id),
              )),

          const SizedBox(height: 28),

          // CTA
          _CtaButton(
            plans: widget.plans,
            selectedPlanId: _selectedPlanId,
          ),

          const SizedBox(height: 16),
          Text(
            'Cancel anytime. No hidden fees.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Plan card
// =============================================================================
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popular badge
            if (plan.isHighlighted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + radio
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.copBlue,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.copBlue,
                        ),
                      ),
                      if (!plan.isFree) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            plan.billingLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (plan.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  // Features
                  if (plan.features.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...plan.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Icon(
                              f.isIncluded
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 18,
                              color: f.isIncluded
                                  ? AppColors.successColor
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: f.isIncluded
                                      ? AppColors.copBlue
                                      : Colors.grey[500],
                                  decoration: f.isIncluded
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CTA button
// =============================================================================
class _CtaButton extends ConsumerStatefulWidget {
  final List<SubscriptionPlan> plans;
  final String selectedPlanId;

  const _CtaButton({
    required this.plans,
    required this.selectedPlanId,
  });

  @override
  ConsumerState<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends ConsumerState<_CtaButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.plans.firstWhere(
      (p) => p.id == widget.selectedPlanId,
      orElse: () => widget.plans.first,
    );

    if (selected.isFree) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AppColors.primaryColor),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(
          'Continue with Free',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : () => _handleUpgrade(selected),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              'Get ${selected.name}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }

  Future<void> _handleUpgrade(SubscriptionPlan plan) async {
    if (plan.stripePriceId == null) {
      _showError('This plan is not yet available for purchase. Please try again later.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref
        .read(stripeServiceProvider)
        .startIndividualCheckout(plan.stripePriceId!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      _showError(result.error ?? 'Could not open payment page. Please try again.');
    }
    // On success: Stripe Checkout opens in external browser.
    // The webhook will update profiles.plan_type when payment completes.
    // When the user returns to the app, they can refresh their profile.
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// Error state
// =============================================================================
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Could not load plans'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper: show paywall as a modal bottom sheet
// =============================================================================
Future<void> showPaywall(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PaywallScreen(isModal: true),
  );
}
