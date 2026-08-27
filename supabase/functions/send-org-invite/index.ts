// =============================================================================
// send-org-invite
//
// Triggered by a Supabase database webhook on:
//   INSERT  into org_members
//   INSERT  into sponsored_grants
//
// Webhook payload shape (Supabase sends the full record as `record`):
// {
//   "type": "INSERT",
//   "table": "org_members" | "sponsored_grants",
//   "record": { ...row fields },
//   "schema": "public"
// }
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { sendEmail } from '../_shared/mailer.ts';
import {
  orgInviteTemplate,
  sponsoredGrantTemplate,
} from '../_shared/email_templates.ts';

const APP_STORE_URL = Deno.env.get('APP_STORE_URL') ?? '';
const PLAY_STORE_URL = Deno.env.get('PLAY_STORE_URL') ?? '';

serve(async (req: Request) => {
  // Supabase webhooks always use POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Verify the webhook secret so only Supabase can call this function
  const webhookSecret = Deno.env.get('WEBHOOK_SECRET');
  if (webhookSecret) {
    const authHeader = req.headers.get('x-webhook-secret');
    if (authHeader !== webhookSecret) {
      return new Response('Unauthorized', { status: 401 });
    }
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response('Invalid JSON body', { status: 400 });
  }

  const table = body.table as string;
  const record = body.record as Record<string, unknown>;

  if (!record) {
    return new Response('No record in payload', { status: 400 });
  }

  try {
    if (table === 'org_members') {
      await handleOrgMemberInvite(record);
    } else if (table === 'sponsored_grants') {
      await handleSponsoredGrantInvite(record);
    } else {
      return new Response(`Unhandled table: ${table}`, { status: 400 });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('send-org-invite error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

async function handleOrgMemberInvite(
  record: Record<string, unknown>,
): Promise<void> {
  const inviteEmail = record.invite_email as string;
  const orgId = record.org_id as string;
  const role = (record.role as string) ?? 'member';

  if (!inviteEmail || !orgId) {
    throw new Error('Missing invite_email or org_id on org_members record');
  }

  // Admin invites are handled by the invite-org-admin edge function which
  // sends the org portal login email (with temp password) directly.
  // Skip here to avoid sending the wrong (app download) email.
  if (role === 'admin') {
    console.log(`Skipping webhook email for admin ${inviteEmail} — handled by invite-org-admin`);
    return;
  }

  const orgName = await fetchOrgName(orgId);
  const { subject, html } = orgInviteTemplate({
    orgName,
    inviteEmail,
    role,
    appStoreUrl: APP_STORE_URL,
    playStoreUrl: PLAY_STORE_URL,
  });

  await sendEmail({ to: inviteEmail, subject, html });
  console.log(`Org invite email sent to ${inviteEmail} for org ${orgName}`);
}

async function handleSponsoredGrantInvite(
  record: Record<string, unknown>,
): Promise<void> {
  const inviteEmail = record.invite_email as string;
  const orgId = record.sponsor_org_id as string;
  const validUntil = record.valid_until as string | null;

  if (!inviteEmail || !orgId) {
    throw new Error(
      'Missing invite_email or sponsor_org_id on sponsored_grants record',
    );
  }

  const orgName = await fetchOrgName(orgId);
  const { subject, html } = sponsoredGrantTemplate({
    orgName,
    inviteEmail,
    validUntil,
    appStoreUrl: APP_STORE_URL,
    playStoreUrl: PLAY_STORE_URL,
  });

  await sendEmail({ to: inviteEmail, subject, html });
  console.log(
    `Sponsored grant email sent to ${inviteEmail} for org ${orgName}`,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function fetchOrgName(orgId: string): Promise<string> {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await supabase
    .from('organizations')
    .select('name')
    .eq('id', orgId)
    .single();

  if (error || !data) {
    throw new Error(`Could not fetch org name for id ${orgId}: ${error?.message}`);
  }

  return data.name as string;
}
