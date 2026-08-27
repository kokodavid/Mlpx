// =============================================================================
// send-member-removed
//
// Triggered by a Supabase database webhook on:
//   UPDATE on org_members WHERE new.status = 'removed'
//
// Webhook payload shape:
// {
//   "type": "UPDATE",
//   "table": "org_members",
//   "record": { ...new row },
//   "old_record": { ...old row },
//   "schema": "public"
// }
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { sendEmail } from '../_shared/mailer.ts';
import { memberRemovedTemplate } from '../_shared/email_templates.ts';

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Verify webhook secret
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

  const record    = body.record     as Record<string, unknown>;
  const oldRecord = body.old_record as Record<string, unknown> | undefined;

  if (!record) {
    return new Response('No record in payload', { status: 400 });
  }

  const newStatus = record.status as string;
  const oldStatus = oldRecord?.status as string | undefined;

  // Only fire when status actually changes to 'removed'
  if (newStatus !== 'removed' || oldStatus === 'removed') {
    return new Response(JSON.stringify({ ok: true, skipped: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const inviteEmail = record.invite_email as string;
    const orgId       = record.org_id as string;

    if (!inviteEmail || !orgId) {
      throw new Error('Missing invite_email or org_id on record');
    }

    const orgName = await fetchOrgName(orgId);
    const { subject, html } = memberRemovedTemplate({ orgName, inviteEmail });

    await sendEmail({ to: inviteEmail, subject, html });
    console.log(`Member removed email sent to ${inviteEmail} for org ${orgName}`);

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('send-member-removed error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

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
