// =============================================================================
// create-billing-portal-session
//
// Creates a Stripe Customer Portal session so users / org admins can manage
// their own billing (cancel, update payment method, view invoices, upgrade).
//
// Request body (JSON):
// {
//   "type":      "individual" | "org",
//   "orgId":     "uuid",          // required when type = "org"
//   "returnUrl": "https://..."    // where Stripe sends the user when they're done
// }
//
// Response:
// { "url": "https://billing.stripe.com/..." }
//
// Required secrets:
//   STRIPE_SECRET_KEY
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createBillingPortalSession } from '../_shared/stripe.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: { user }, error: authErr } = await db.auth.getUser(authHeader.slice(7));
  if (authErr || !user) return json({ error: 'Unauthorized' }, 401);

  // ── Body ──────────────────────────────────────────────────────────────────
  let body: { type?: string; orgId?: string; returnUrl?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON' }, 400);
  }

  const { type = 'individual', orgId, returnUrl } = body;
  if (!returnUrl) return json({ error: 'returnUrl is required' }, 400);
  if (type === 'org' && !orgId) return json({ error: 'orgId is required for org type' }, 400);

  try {
    // ── Look up Stripe customer ID ─────────────────────────────────────────
    let customerId: string | null = null;

    if (type === 'org') {
      // Verify the user is an admin of this org
      const { data: membership } = await db
        .from('org_members')
        .select('role')
        .eq('org_id', orgId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .single();

      const { data: org } = await db
        .from('organizations')
        .select('stripe_customer_id, owner_id')
        .eq('id', orgId)
        .single();

      if (!org) return json({ error: 'Organization not found' }, 404);

      const isOwner = (org.owner_id as string) === user.id;
      const isAdmin = (membership?.role as string) === 'admin';
      if (!isOwner && !isAdmin) return json({ error: 'Forbidden' }, 403);

      customerId = org.stripe_customer_id as string | null;

    } else {
      const { data: profile } = await db
        .from('profiles')
        .select('stripe_customer_id')
        .eq('id', user.id)
        .single();

      customerId = profile?.stripe_customer_id as string | null;
    }

    if (!customerId) {
      return json({
        error: 'No billing account found. Please subscribe first.',
        code: 'NO_STRIPE_CUSTOMER',
      }, 404);
    }

    // ── Create billing portal session ──────────────────────────────────────
    const session = await createBillingPortalSession({
      customerId,
      returnUrl,
    });

    return json({ url: session.url });

  } catch (err) {
    console.error('create-billing-portal-session error:', err);
    return json({ error: (err as Error).message }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
