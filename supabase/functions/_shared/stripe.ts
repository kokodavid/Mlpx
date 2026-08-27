// =============================================================================
// _shared/stripe.ts
//
// Thin helpers for working with the Stripe API from Deno Edge Functions.
// We call the Stripe REST API directly via fetch (no npm SDK needed in Deno).
//
// Required environment variables:
//   STRIPE_SECRET_KEY      — sk_test_... or sk_live_...
//   STRIPE_WEBHOOK_SECRET  — whsec_... (from Stripe dashboard → Webhooks)
// =============================================================================

export const STRIPE_API = 'https://api.stripe.com/v1';

/** Returns the Stripe secret key or throws if missing. */
export function stripeKey(): string {
  const key = Deno.env.get('STRIPE_SECRET_KEY');
  if (!key) throw new Error('STRIPE_SECRET_KEY env var is not set');
  return key;
}

/** Base64url decode (used in webhook signature verification). */
function base64Decode(str: string): Uint8Array {
  return Uint8Array.from(atob(str), (c) => c.charCodeAt(0));
}

// ---------------------------------------------------------------------------
// Stripe webhook signature verification
// ---------------------------------------------------------------------------

/**
 * Verifies the Stripe-Signature header and returns the parsed event body.
 * Throws if the signature is invalid or the timestamp is too old (5 min).
 */
export async function constructStripeEvent(
  rawBody: string,
  signatureHeader: string,
): Promise<Record<string, unknown>> {
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
  if (!webhookSecret) {
    throw new Error('STRIPE_WEBHOOK_SECRET env var is not set');
  }

  // Parse Stripe-Signature: t=...,v1=...
  const parts: Record<string, string> = {};
  for (const part of signatureHeader.split(',')) {
    const [k, v] = part.split('=');
    if (k && v) parts[k] = v;
  }

  const timestamp = parts['t'];
  const signature = parts['v1'];
  if (!timestamp || !signature) {
    throw new Error('Invalid Stripe-Signature header');
  }

  // Reject events older than 5 minutes
  const ts = parseInt(timestamp, 10);
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - ts) > 300) {
    throw new Error('Stripe webhook timestamp too old');
  }

  // HMAC-SHA256 of "timestamp.rawBody"
  const enc = new TextEncoder();
  const keyBytes = enc.encode(webhookSecret);
  const msgBytes = enc.encode(`${timestamp}.${rawBody}`);

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const sigBytes = await crypto.subtle.sign('HMAC', cryptoKey, msgBytes);

  // Convert to hex for comparison
  const expected = Array.from(new Uint8Array(sigBytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  if (expected !== signature) {
    throw new Error('Stripe webhook signature mismatch');
  }

  return JSON.parse(rawBody) as Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Stripe API helpers
// ---------------------------------------------------------------------------

type StripeBody = Record<string, string | number | boolean | undefined | null>;

/** Encodes an object as application/x-www-form-urlencoded for Stripe. */
function encodeForm(obj: StripeBody, prefix = ''): string {
  return Object.entries(obj)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => {
      const key = prefix ? `${prefix}[${k}]` : k;
      return `${encodeURIComponent(key)}=${encodeURIComponent(String(v))}`;
    })
    .join('&');
}

/** Generic Stripe API call. */
export async function stripeRequest<T = Record<string, unknown>>(
  method: 'GET' | 'POST',
  path: string,
  body?: StripeBody,
): Promise<T> {
  const res = await fetch(`${STRIPE_API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${stripeKey()}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body ? encodeForm(body) : undefined,
  });

  const json = await res.json();
  if (!res.ok) {
    const msg = (json as { error?: { message?: string } }).error?.message ?? 'Stripe API error';
    throw new Error(`Stripe ${method} ${path} → ${res.status}: ${msg}`);
  }

  return json as T;
}

// ---------------------------------------------------------------------------
// Customer helpers
// ---------------------------------------------------------------------------

interface StripeCustomer {
  id: string;
  email?: string;
}

/** Looks up a Stripe customer by email. Returns undefined if none found. */
export async function findCustomerByEmail(
  email: string,
): Promise<StripeCustomer | undefined> {
  const result = await stripeRequest<{ data: StripeCustomer[] }>(
    'GET',
    `/customers?email=${encodeURIComponent(email)}&limit=1`,
  );
  return result.data[0];
}

/** Creates a new Stripe customer. */
export async function createCustomer(params: {
  email?: string;
  name?: string;
  metadata?: Record<string, string>;
}): Promise<StripeCustomer> {
  const body: StripeBody = {};
  if (params.email) body['email'] = params.email;
  if (params.name) body['name'] = params.name;
  if (params.metadata) {
    for (const [k, v] of Object.entries(params.metadata)) {
      body[`metadata[${k}]`] = v;
    }
  }
  return stripeRequest<StripeCustomer>('POST', '/customers', body);
}

// ---------------------------------------------------------------------------
// Checkout session
// ---------------------------------------------------------------------------

export interface CheckoutSessionParams {
  customerId: string;
  priceId: string;
  /** 'individual' | 'org' */
  type: string;
  userId: string;
  orgId?: string;
  successUrl: string;
  cancelUrl: string;
}

export async function createCheckoutSession(
  params: CheckoutSessionParams,
): Promise<{ id: string; url: string }> {
  const body: StripeBody = {
    customer: params.customerId,
    'line_items[0][price]': params.priceId,
    'line_items[0][quantity]': 1,
    mode: 'subscription',
    success_url: params.successUrl,
    cancel_url: params.cancelUrl,
    client_reference_id: params.userId,
    // Embed context so the webhook knows who to update
    'metadata[type]': params.type,
    'metadata[user_id]': params.userId,
    // Allow promo codes
    allow_promotion_codes: true,
    // Collect billing address for tax
    billing_address_collection: 'auto',
  };

  if (params.orgId) {
    body['metadata[org_id]'] = params.orgId;
    body['subscription_data[metadata][type]'] = 'org';
    body['subscription_data[metadata][org_id]'] = params.orgId;
  } else {
    body['subscription_data[metadata][type]'] = 'individual';
    body['subscription_data[metadata][user_id]'] = params.userId;
  }

  return stripeRequest('POST', '/checkout/sessions', body);
}

// ---------------------------------------------------------------------------
// Billing portal
// ---------------------------------------------------------------------------

export async function createBillingPortalSession(params: {
  customerId: string;
  returnUrl: string;
}): Promise<{ url: string }> {
  return stripeRequest('POST', '/billing_portal/sessions', {
    customer: params.customerId,
    return_url: params.returnUrl,
  });
}
