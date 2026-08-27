import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// StripeService
//
// Talks to the two Stripe Edge Functions:
//   - create-checkout-session
//   - create-billing-portal-session
//
// Uses Supabase's built-in functions client so the user's auth token is
// automatically attached to every request.
// =============================================================================
class StripeService {
  final SupabaseClient _client;

  StripeService(this._client);

  // ── Success / cancel URLs ───────────────────────────────────────────────
  // These are web pages the Stripe-hosted checkout redirects to after payment.
  // Replace with your actual hosted pages or deep link handlers.
  static const _successUrl =
      'https://milpress.app/payment/success?session_id={CHECKOUT_SESSION_ID}';
  static const _cancelUrl =
      'https://milpress.app/payment/cancelled';

  // For the org portal dashboard:
  static const _orgReturnUrl = 'https://milpress.app/org/settings';

  // ── Individual checkout ─────────────────────────────────────────────────

  /// Opens Stripe Checkout for an individual subscription.
  /// [priceId] must be a valid Stripe Price ID stored in subscription_plans.
  Future<StripeResult> startIndividualCheckout(String priceId) async {
    return _callCheckout(
      type: 'individual',
      priceId: priceId,
    );
  }

  // ── Org checkout ────────────────────────────────────────────────────────

  /// Opens Stripe Checkout for an org subscription.
  Future<StripeResult> startOrgCheckout({
    required String priceId,
    required String orgId,
    String? returnUrl,
  }) async {
    return _callCheckout(
      type: 'org',
      priceId: priceId,
      orgId: orgId,
      successUrl: returnUrl != null
          ? '$returnUrl?payment=success'
          : _orgReturnUrl,
      cancelUrl: returnUrl ?? _orgReturnUrl,
    );
  }

  // ── Billing portal ──────────────────────────────────────────────────────

  /// Opens the Stripe Customer Portal for self-service billing management.
  Future<StripeResult> openBillingPortal({
    String type = 'individual',
    String? orgId,
    String? returnUrl,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-billing-portal-session',
        body: {
          'type': type,
          if (orgId != null) 'orgId': orgId,
          'returnUrl': returnUrl ?? _orgReturnUrl,
        },
      );

      final data = _parseResponse(response);
      final url = data['url'] as String?;
      if (url == null) throw Exception('No URL in billing portal response');

      return _launchUrl(url);
    } catch (e) {
      return StripeResult.error(e.toString());
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<StripeResult> _callCheckout({
    required String type,
    required String priceId,
    String? orgId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-checkout-session',
        body: {
          'type': type,
          'priceId': priceId,
          if (orgId != null) 'orgId': orgId,
          'successUrl': successUrl ?? _successUrl,
          'cancelUrl': cancelUrl ?? _cancelUrl,
        },
      );

      final data = _parseResponse(response);
      final url = data['url'] as String?;
      if (url == null) throw Exception('No URL in checkout response');

      return _launchUrl(url);
    } catch (e) {
      return StripeResult.error(e.toString());
    }
  }

  Map<String, dynamic> _parseResponse(FunctionResponse response) {
    if (response.status != 200) {
      final body = response.data;
      String msg = 'Payment service error (${response.status})';
      if (body is Map) msg = (body['error'] as String?) ?? msg;
      throw Exception(msg);
    }
    if (response.data is Map) return Map<String, dynamic>.from(response.data as Map);
    if (response.data is String) {
      return Map<String, dynamic>.from(
        jsonDecode(response.data as String) as Map,
      );
    }
    throw Exception('Unexpected response format from payment service');
  }

  Future<StripeResult> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      return StripeResult.error('Could not open payment page. Please try again.');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return StripeResult.launched();
  }
}

// =============================================================================
// StripeResult — returned from every Stripe operation
// =============================================================================
class StripeResult {
  final bool success;
  final String? error;

  const StripeResult._({required this.success, this.error});

  factory StripeResult.launched() => const StripeResult._(success: true);
  factory StripeResult.error(String msg) => StripeResult._(success: false, error: msg);
}

// =============================================================================
// Providers
// =============================================================================

final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService(Supabase.instance.client);
});
