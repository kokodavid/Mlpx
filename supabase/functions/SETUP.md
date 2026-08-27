# Edge Functions — Email Setup

## Functions

| Function | Trigger | Purpose |
|---|---|---|
| `send-org-invite` | INSERT on `org_members` | Email when admin invites a user to an org |
| `send-org-invite` | INSERT on `sponsored_grants` | Email when admin creates a sponsored grant |
| `send-grant-revoked` | UPDATE on `sponsored_grants` | Email when a grant is revoked |

Emails are sent via your existing Hostinger SMTP — no third-party email service needed.

---

## 1. Deploy the functions

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login and link to your project
supabase login
supabase link --project-ref <your-project-ref>

# Deploy both functions
supabase functions deploy send-org-invite --no-verify-jwt
supabase functions deploy send-grant-revoked --no-verify-jwt
```

> `--no-verify-jwt` is needed because the functions are called by database webhooks, not by logged-in users.

---

## 2. Set environment variables

In Supabase dashboard → **Project Settings → Edge Functions → Environment variables**, add:

| Key | Value |
|---|---|
| `SMTP_HOST` | `smtp.hostinger.com` |
| `SMTP_PORT` | `465` |
| `SMTP_USERNAME` | `info@milpress.org` |
| `SMTP_PASSWORD` | Your Hostinger email password |
| `SMTP_FROM_EMAIL` | `info@milpress.org` |
| `SMTP_FROM_NAME` | `Milpress Educational` |
| `WEBHOOK_SECRET` | A random string — run `openssl rand -hex 32` to generate one |
| `APP_STORE_URL` | Your iOS App Store link (optional) |
| `PLAY_STORE_URL` | Your Google Play link (optional) |

---

## 3. Create the database webhooks

In Supabase dashboard → **Database → Webhooks → Create new webhook**:

### Webhook 1 — Org member invited
- **Name:** `org_member_invited`
- **Table:** `org_members`
- **Events:** `INSERT`
- **URL:** `https://<project-ref>.supabase.co/functions/v1/send-org-invite`
- **HTTP Headers:**
  - `x-webhook-secret`: *(same value as `WEBHOOK_SECRET` env var)*

### Webhook 2 — Sponsored grant created
- **Name:** `sponsored_grant_created`
- **Table:** `sponsored_grants`
- **Events:** `INSERT`
- **URL:** `https://<project-ref>.supabase.co/functions/v1/send-org-invite`
- **HTTP Headers:**
  - `x-webhook-secret`: *(same value as `WEBHOOK_SECRET` env var)*

### Webhook 3 — Grant revoked
- **Name:** `sponsored_grant_revoked`
- **Table:** `sponsored_grants`
- **Events:** `UPDATE`
- **URL:** `https://<project-ref>.supabase.co/functions/v1/send-grant-revoked`
- **HTTP Headers:**
  - `x-webhook-secret`: *(same value as `WEBHOOK_SECRET` env var)*

> `send-grant-revoked` filters internally — it only sends when `status` changes to `'revoked'`, so firing on all UPDATEs is safe.

---

## 4. Test

```bash
# Test org member invite
supabase functions invoke send-org-invite --body '{
  "type": "INSERT",
  "table": "org_members",
  "schema": "public",
  "record": {
    "id": "test-id",
    "org_id": "<real-org-id>",
    "invite_email": "yourtestemail@example.com",
    "role": "member",
    "status": "pending"
  }
}'

# Test sponsored grant invite
supabase functions invoke send-org-invite --body '{
  "type": "INSERT",
  "table": "sponsored_grants",
  "schema": "public",
  "record": {
    "id": "test-id",
    "sponsor_org_id": "<real-org-id>",
    "invite_email": "yourtestemail@example.com",
    "status": "active"
  }
}'

# Test grant revocation
supabase functions invoke send-grant-revoked --body '{
  "type": "UPDATE",
  "table": "sponsored_grants",
  "schema": "public",
  "record": {
    "id": "test-id",
    "sponsor_org_id": "<real-org-id>",
    "invite_email": "yourtestemail@example.com",
    "status": "revoked",
    "revoke_reason": "Test revocation"
  },
  "old_record": {
    "status": "active"
  }
}'
```
