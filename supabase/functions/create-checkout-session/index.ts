// =============================================================================
// create-checkout-session
//
// Creates a Stripe Checkout Session and returns the redirect URL.
// Called by both the mobile app (individual subscriptions) and the org portal
// dashboard (org subscriptions).
//
// Request body (JSON):
// {
//   "type":       "individual" | "org",
//   "priceId":    "price_xxx",           // Stripe Price ID from subscription_plans table
//   "orgId":      "uuid",                // required when type = "org"
//   "successUrl": "https://...",         // where to redirect after payment
//   "cancelUrl":  "https://..."          // where to redirect if user cancels
// }
//
// Response:
// { "url": "https://checkout.stripe.com/..." }
//
// Required secrets:
//   STRIPE_SECRET_KEY
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  findCustomerByEmail,
  createCustomer,
  createCheckoutSession,
} from '../_shared/stripe.ts';

// ---------------------------------------------------------------------------
// CORS headers — required for calls from the Flutter web dashboard
// ---------------------------------------------------------------------------
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  // Preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  // ── Auth: verify the caller is a logged-in Supabase user ────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Missing or invalid Authorization header' }, 401);
  }
  const token = authHeader.slice(7);

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: { user }, error: authError } = await db.auth.getUser(token);
  if (authError || !user) {
    return json({ error: 'Unauthorized' }, 401);
  }

  // ── Parse body ───────────────────────────────────────────────────────────
  let body: {
    type?: string;
    priceId?: string;
    orgId?: string;
    successUrl?: string;
    cancelUrl?: string;
  };

  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const { type = 'individual', priceId, orgId, successUrl, cancelUrl } = body;

  if (!priceId)    return json({ error: 'priceId is required' }, 400);
  if (!successUrl) return json({ error: 'successUrl is required' }, 400);
  if (!cancelUrl)  return json({ error: 'cancelUrl is required' }, 400);
  if (type === 'org' && !orgId) return json({ error: 'orgId is required for org type' }, 400);

  try {
    // ── Resolve or create Stripe customer ───────────────────────────────────
    let stripeCustomerId: string;

    if (type === 'org') {
      stripeCustomerId = await ensureOrgCustomer(db, orgId!, user.id);
    } else {
      stripeCustomerId = await ensureUserCustomer(db, user);
    }

    // ── Create Stripe Checkout Session ──────────────────────────────────────
    const session = await createCheckoutSession({
      customerId: stripeCustomerId,
      priceId,
      type,
      userId: user.id,
      orgId,
      successUrl,
      cancelUrl,
    });

    return json({ url: session.url, sessionId: session.id });

  } catch (err) {
    console.error('create-checkout-session error:', err);
    return json({ error: (err as Error).message }, 500);
  }
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function ensureUserCustomer(
  db: ReturnType<typeof createClient>,
  user: { id: string; email?: string },
): Promise<string> {
  // Check if we already have a customer ID stored
  const { data: profile } = await db
    .from('profiles')
    .select('stripe_customer_id, email, first_name, last_name')
    .eq('id', user.id)
    .single();

  if (profile?.stripe_customer_id) {
    return profile.stripe_customer_id as string;
  }

  // Look up by email in Stripe
  const email = (profile?.email as string) ?? user.email ?? '';
  let customer = email ? await findCustomerByEmail(email) : undefined;

  if (!customer) {
    const name = [profile?.first_name, profile?.last_name]
      .filter(Boolean)
      .join(' ') || undefined;
    customer = await createCustomer({
      email,
      name,
      metadata: { supabase_user_id: user.id },
    });
  }

  // Persist for future calls
  await db
    .from('profiles')
    .update({ stripe_customer_id: customer.id })
    .eq('id', user.id);

  return customer.id;
}

async function ensureOrgCustomer(
  db: ReturnType<typeof createClient>,
  orgId: string,
  requestingUserId: string,
): Promise<string> {
  // Verify the requesting user is an admin of this org
  const { data: membership } = await db
    .from('org_members')
    .select('role')
    .eq('org_id', orgId)
    .eq('user_id', requestingUserId)
    .eq('status', 'active')
    .single();

  const { data: org } = await db
    .from('organizations')
    .select('id, name, stripe_customer_id, owner_id')
    .eq('id', orgId)
    .single();

  if (!org) throw new Error('Organization not found');

  // Must be owner or admin member
  const isOwner  = (org.owner_id as string) === requestingUserId;
  const isAdmin  = (membership?.role as string) === 'admin';
  if (!isOwner && !isAdmin) {
    throw new Error('Forbidden: user is not an admin of this organization');
  }

  if (org.stripe_customer_id) {
    return org.stripe_customer_id as string;
  }

  // Look up by org name in Stripe — use org name as customer name
  const customer = await createCustomer({
    name: org.name as string,
    metadata: { supabase_org_id: orgId, type: 'org' },
  });

  await db
    .from('organizations')
    .update({ stripe_customer_id: customer.id })
    .eq('id', orgId);

  return customer.id;
}

// ---------------------------------------------------------------------------
// Response helper
// ---------------------------------------------------------------------------
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
