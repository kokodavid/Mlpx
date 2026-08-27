// =============================================================================
// invite-org-admin
//
// Called directly from the admin dashboard to invite a user as an org admin.
//
// Flow:
//   1. Verify caller is authenticated
//   2. Generate a secure temp password
//   3. Try to create the Supabase auth account
//      → if already exists, look up via profiles table and reset password
//   4. Upsert an org_members row with role=admin, status=active
//   5. Send the org admin invite email with login credentials
//
// Request body (JSON):
// {
//   "email":        "admin@example.com",
//   "orgId":        "uuid",
//   "orgPortalUrl": "https://..."   // optional, defaults to ORG_PORTAL_URL env
// }
//
// Response:
// { "ok": true, "created": true }
// =============================================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { sendEmail } from '../_shared/mailer.ts';
import { orgAdminInviteTemplate } from '../_shared/email_templates.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ORG_PORTAL_URL =
  Deno.env.get('ORG_PORTAL_URL') ?? 'https://admin-dashboard.milpress.org/#/org-login';

serve(async (req: Request) => {
  // ── CORS preflight ────────────────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return respond({ error: 'Method not allowed' }, 405);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return respond({ error: 'Unauthorized' }, 401);
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: { user: caller }, error: authErr } =
    await db.auth.getUser(authHeader.slice(7));
  if (authErr || !caller) return respond({ error: 'Unauthorized' }, 401);

  // ── Body ──────────────────────────────────────────────────────────────────
  let body: Record<string, string>;
  try {
    body = await req.json();
  } catch {
    return respond({ error: 'Invalid JSON body' }, 400);
  }

  const email      = (body.email      ?? '').trim().toLowerCase();
  const orgId      = (body.orgId      ?? '').trim();
  const portalUrl  = (body.orgPortalUrl ?? ORG_PORTAL_URL).trim();

  if (!email || !email.includes('@')) return respond({ error: 'Valid email is required' }, 400);
  if (!orgId)                         return respond({ error: 'orgId is required' }, 400);

  try {
    // ── 1. Fetch org name ──────────────────────────────────────────────────
    const { data: org, error: orgErr } = await db
      .from('organizations')
      .select('name')
      .eq('id', orgId)
      .single();

    if (orgErr || !org) return respond({ error: 'Organization not found' }, 404);
    const orgName = org.name as string;

    // ── 2. Create or update auth user ──────────────────────────────────────
    const tempPassword = generatePassword();
    let userId: string;
    let accountCreated = false;

    const { data: created, error: createErr } = await db.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: true,
    });

    if (createErr) {
      // User already exists — look up via profiles table
      const isAlreadyExists =
        createErr.message.toLowerCase().includes('already') ||
        (createErr as unknown as { status?: number }).status === 422;

      if (!isAlreadyExists) {
        throw new Error(`Failed to create user: ${createErr.message}`);
      }

      const { data: profile, error: profileErr } = await db
        .from('profiles')
        .select('id')
        .eq('email', email)
        .single();

      if (profileErr || !profile) {
        throw new Error(`Could not find existing user with email ${email}`);
      }

      userId = profile.id as string;

      // Reset password so we can share it in the invite email
      const { error: updateErr } = await db.auth.admin.updateUserById(userId, {
        password: tempPassword,
      });
      if (updateErr) throw new Error(`Failed to reset password: ${updateErr.message}`);

    } else if (!created.user) {
      throw new Error('Failed to create auth user: no user returned');
    } else {
      userId   = created.user.id;
      accountCreated = true;
    }

    // ── 3. Upsert org_members row ──────────────────────────────────────────
    const { error: memberErr } = await db.from('org_members').upsert(
      {
        org_id:       orgId,
        user_id:      userId,
        invite_email: email,
        role:         'admin',
        status:       'active',
        invited_at:   new Date().toISOString(),
      },
      { onConflict: 'org_id,invite_email' },
    );

    if (memberErr) throw new Error(`Failed to upsert org_members: ${memberErr.message}`);

    // ── 4. Send invite email ───────────────────────────────────────────────
    const { subject, html } = orgAdminInviteTemplate({
      orgName,
      inviteEmail: email,
      tempPassword,
      orgPortalUrl: portalUrl,
    });

    await sendEmail({ to: email, subject, html });

    console.log(`Org admin invite sent → ${email} / org: ${orgName} / created: ${accountCreated}`);

    return respond({ ok: true, created: accountCreated });

  } catch (err) {
    console.error('invite-org-admin error:', err);
    return respond({ error: (err as Error).message }, 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function generatePassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%';
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => chars[b % chars.length]).join('');
}

function respond(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
