// =============================================================================
// stripe-webhook
//
// Receives Stripe webhook events and updates the Supabase database.
//
// Register this URL in Stripe Dashboard → Developers → Webhooks:
//   https://<project>.supabase.co/functions/v1/stripe-webhook
//
// Events to enable:
//   checkout.session.completed
//   customer.subscription.created
//   customer.subscription.updated
//   customer.subscription.deleted
//   invoice.payment_succeeded
//   invoice.payment_failed
//
// Required secrets (set via `supabase secrets set`):
//   STRIPE_SECRET_KEY
//   STRIPE_WEBHOOK_SECRET
//   SUPABASE_URL             (auto-set by Supabase)
//   SUPABASE_SERVICE_ROLE_KEY (auto-set by Supabase)
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { constructStripeEvent } from '../_shared/stripe.ts';

// ---------------------------------------------------------------------------
// Types (minimal — we only read the fields we need)
// ---------------------------------------------------------------------------

interface StripeSubscription {
  id: string;
  customer: string;
  status: string;
  items: { data: Array<{ price: { id: string; product: string } }> };
  current_period_start: number;
  current_period_end: number;
  cancel_at_period_end: boolean;
  canceled_at: number | null;
  metadata: Record<string, string>;
}

interface StripeCheckoutSession {
  id: string;
  customer: string | null;
  client_reference_id: string | null;
  subscription: string | null;
  metadata: Record<string, string>;
}

interface StripeInvoice {
  id: string;
  customer: string;
  subscription: string | null;
  status: string;
}

// ---------------------------------------------------------------------------
// Supabase client (service role — bypasses RLS)
// ---------------------------------------------------------------------------

function supabase() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const rawBody = await req.text();
  const sig = req.headers.get('stripe-signature');

  if (!sig) {
    return new Response('Missing stripe-signature header', { status: 400 });
  }

  let event: Record<string, unknown>;
  try {
    event = await constructStripeEvent(rawBody, sig);
  } catch (err) {
    console.error('Webhook signature error:', (err as Error).message);
    return new Response(`Webhook Error: ${(err as Error).message}`, { status: 400 });
  }

  const eventType = event['type'] as string;
  const data = event['data'] as { object: Record<string, unknown> };
  const obj = data.object;

  console.log(`Processing Stripe event: ${eventType}`);

  try {
    switch (eventType) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(obj as unknown as StripeCheckoutSession);
        break;

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpsert(obj as unknown as StripeSubscription);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(obj as unknown as StripeSubscription);
        break;

      case 'invoice.payment_succeeded':
        await handleInvoiceSucceeded(obj as unknown as StripeInvoice);
        break;

      case 'invoice.payment_failed':
        await handleInvoiceFailed(obj as unknown as StripeInvoice);
        break;

      default:
        console.log(`Unhandled event type: ${eventType}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error(`Error handling ${eventType}:`, err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

// ---------------------------------------------------------------------------
// checkout.session.completed
// Fires once after the user successfully pays on the Stripe-hosted page.
// We use this to store stripe_customer_id and link the subscription.
// ---------------------------------------------------------------------------

async function handleCheckoutCompleted(
  session: StripeCheckoutSession,
): Promise<void> {
  const { customer, client_reference_id, subscription: subId, metadata } = session;
  const type = metadata?.['type'] ?? 'individual';
  const db = supabase();

  if (!customer || !subId) {
    console.warn('checkout.session.completed: missing customer or subscription');
    return;
  }

  if (type === 'org') {
    const orgId = metadata['org_id'];
    if (!orgId) throw new Error('checkout.session.completed org: missing org_id in metadata');

    // Save stripe_customer_id on the org
    await db
      .from('organizations')
      .update({
        stripe_customer_id: customer,
        stripe_subscription_id: subId,
      })
      .eq('id', orgId);

    console.log(`Org ${orgId} linked to Stripe customer ${customer}`);

  } else {
    // Individual — client_reference_id is the user's Supabase UID
    const userId = client_reference_id ?? metadata['user_id'];
    if (!userId) throw new Error('checkout.session.completed: missing user_id');

    // Save stripe_customer_id on the profile
    await db
      .from('profiles')
      .update({
        stripe_customer_id: customer,
        stripe_subscription_id: subId,
      })
      .eq('id', userId);

    console.log(`User ${userId} linked to Stripe customer ${customer}`);
  }
}

// ---------------------------------------------------------------------------
// customer.subscription.created / updated
// The primary event for keeping subscription data in sync.
// ---------------------------------------------------------------------------

async function handleSubscriptionUpsert(sub: StripeSubscription): Promise<void> {
  const db = supabase();
  const { id: stripeSubId, customer, status, metadata } = sub;
  const type = metadata?.['type'];

  const periodStart = new Date(sub.current_period_start * 1000).toISOString();
  const periodEnd   = new Date(sub.current_period_end   * 1000).toISOString();
  const cancelledAt = sub.canceled_at
    ? new Date(sub.canceled_at * 1000).toISOString()
    : null;

  // Map Stripe status to our sub_status enum
  const subStatus = mapStripeStatus(status);

  // Get Stripe price → map to our plan type
  const priceId = sub.items.data[0]?.price?.id;

  if (type === 'org') {
    const orgId = metadata['org_id'];
    if (!orgId) {
      console.warn('subscription upsert: missing org_id in metadata');
      return;
    }

    // Resolve org_plan from the price
    const orgPlan = await resolveOrgPlan(db, priceId);

    // Upsert org_subscriptions
    await db.from('org_subscriptions').upsert(
      {
        org_id:               orgId,
        plan:                 orgPlan,
        status:               subStatus,
        billing_cycle:        inferBillingCycle(sub),
        amount_usd:           null,        // populated from invoice if needed
        current_period_start: periodStart,
        current_period_end:   periodEnd,
        payment_provider:     'stripe',
        external_sub_id:      stripeSubId,
        external_customer_id: customer,
        cancelled_at:         cancelledAt,
        cancel_at_period_end: sub.cancel_at_period_end,
        updated_at:           new Date().toISOString(),
      },
      { onConflict: 'external_sub_id' },
    );

    // Sync organizations.plan and .status
    await db
      .from('organizations')
      .update({
        plan:   orgPlan,
        status: subStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('stripe_subscription_id', stripeSubId);

    console.log(`Org subscription ${stripeSubId} upserted (status: ${subStatus})`);

  } else {
    // Individual
    const userId = metadata['user_id'] ?? await userIdByCustomer(db, customer);
    if (!userId) {
      console.warn(`subscription upsert: no user found for customer ${customer}`);
      return;
    }

    const planType = subStatus === 'active' || subStatus === 'trialing'
      ? 'premium'
      : 'free';

    // Upsert subscriptions
    await db.from('subscriptions').upsert(
      {
        user_id:              userId,
        plan:                 planType,
        status:               subStatus,
        billing_cycle:        inferBillingCycle(sub),
        current_period_start: periodStart,
        current_period_end:   periodEnd,
        payment_provider:     'stripe',
        external_sub_id:      stripeSubId,
        external_customer_id: customer,
        cancelled_at:         cancelledAt,
        cancel_at_period_end: sub.cancel_at_period_end,
        updated_at:           new Date().toISOString(),
      },
      { onConflict: 'external_sub_id' },
    );

    // Flip profiles.plan_type
    await db
      .from('profiles')
      .update({ plan_type: planType, updated_at: new Date().toISOString() })
      .eq('id', userId);

    console.log(`Individual subscription ${stripeSubId} upserted for user ${userId} (plan: ${planType})`);
  }
}

// ---------------------------------------------------------------------------
// customer.subscription.deleted
// Fires when a subscription is fully cancelled (period end passed).
// ---------------------------------------------------------------------------

async function handleSubscriptionDeleted(sub: StripeSubscription): Promise<void> {
  const db = supabase();
  const { id: stripeSubId, metadata } = sub;
  const type = metadata?.['type'];

  if (type === 'org') {
    await db
      .from('org_subscriptions')
      .update({
        status:      'cancelled',
        cancelled_at: new Date().toISOString(),
        updated_at:  new Date().toISOString(),
      })
      .eq('external_sub_id', stripeSubId);

    await db
      .from('organizations')
      .update({ status: 'cancelled', updated_at: new Date().toISOString() })
      .eq('stripe_subscription_id', stripeSubId);

    console.log(`Org subscription ${stripeSubId} cancelled`);

  } else {
    const userId = metadata['user_id'] ?? await userIdByStripeSubId(db, stripeSubId);
    if (!userId) return;

    await db
      .from('subscriptions')
      .update({
        status:       'cancelled',
        cancelled_at: new Date().toISOString(),
        updated_at:   new Date().toISOString(),
      })
      .eq('external_sub_id', stripeSubId);

    // Downgrade profile
    await db
      .from('profiles')
      .update({ plan_type: 'free', updated_at: new Date().toISOString() })
      .eq('id', userId);

    console.log(`Individual subscription ${stripeSubId} cancelled for user ${userId}`);
  }
}

// ---------------------------------------------------------------------------
// invoice.payment_succeeded
// Fires on every successful renewal. Updates period dates.
// ---------------------------------------------------------------------------

async function handleInvoiceSucceeded(invoice: StripeInvoice): Promise<void> {
  const db = supabase();
  if (!invoice.subscription) return;

  // Re-use upsert by fetching the subscription object from Stripe and processing it
  // (Stripe sends billing_reason + lines which we'd parse — simpler to just call
  //  handleSubscriptionUpsert via a fresh subscription fetch if needed)
  // For now: clear past_due if that was set, and trust that subscription.updated
  // will follow with updated period dates.
  await db
    .from('subscriptions')
    .update({ status: 'active', updated_at: new Date().toISOString() })
    .eq('external_sub_id', invoice.subscription)
    .eq('status', 'past_due');

  await db
    .from('org_subscriptions')
    .update({ status: 'active', updated_at: new Date().toISOString() })
    .eq('external_sub_id', invoice.subscription)
    .eq('status', 'past_due');

  console.log(`Invoice succeeded for subscription ${invoice.subscription}`);
}

// ---------------------------------------------------------------------------
// invoice.payment_failed
// Fires when a renewal payment fails. Marks the subscription past_due.
// ---------------------------------------------------------------------------

async function handleInvoiceFailed(invoice: StripeInvoice): Promise<void> {
  const db = supabase();
  if (!invoice.subscription) return;

  await db
    .from('subscriptions')
    .update({ status: 'past_due', updated_at: new Date().toISOString() })
    .eq('external_sub_id', invoice.subscription);

  await db
    .from('org_subscriptions')
    .update({ status: 'past_due', updated_at: new Date().toISOString() })
    .eq('external_sub_id', invoice.subscription);

  console.log(`Invoice failed for subscription ${invoice.subscription} — marked past_due`);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function mapStripeStatus(stripeStatus: string): string {
  const map: Record<string, string> = {
    trialing:  'trialing',
    active:    'active',
    past_due:  'past_due',
    canceled:  'cancelled',   // Stripe uses 'canceled' (one 'l')
    unpaid:    'past_due',
    incomplete: 'past_due',
    incomplete_expired: 'expired',
  };
  return map[stripeStatus] ?? 'expired';
}

function inferBillingCycle(sub: StripeSubscription): string {
  // Stripe interval is on the price — approximate from period length
  const days = (sub.current_period_end - sub.current_period_start) / 86400;
  return days > 35 ? 'annual' : 'monthly';
}

async function resolveOrgPlan(
  db: ReturnType<typeof supabase>,
  stripePriceId: string | undefined,
): Promise<string> {
  if (!stripePriceId) return 'starter';
  const { data } = await db
    .from('subscription_plans')
    .select('name')
    .eq('stripe_price_id', stripePriceId)
    .single();
  if (!data) return 'starter';
  const name = (data.name as string).toLowerCase();
  if (name.includes('growth'))     return 'growth';
  if (name.includes('enterprise')) return 'enterprise';
  return 'starter';
}

async function userIdByCustomer(
  db: ReturnType<typeof supabase>,
  customerId: string,
): Promise<string | null> {
  const { data } = await db
    .from('profiles')
    .select('id')
    .eq('stripe_customer_id', customerId)
    .single();
  return (data?.id as string) ?? null;
}

async function userIdByStripeSubId(
  db: ReturnType<typeof supabase>,
  stripeSubId: string,
): Promise<string | null> {
  const { data } = await db
    .from('subscriptions')
    .select('user_id')
    .eq('external_sub_id', stripeSubId)
    .single();
  return (data?.user_id as string) ?? null;
}
