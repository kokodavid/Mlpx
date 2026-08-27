# Organization Portal — Scope Document

**Project:** milpress-dashboard (Flutter web)  
**Date:** 2026-06-28  
**Status:** Scoping / Pre-implementation

---

## 1. Problem Statement

The admin dashboard (`milpress-dashboard`) is currently accessible only to internal Milpress admins. Organizations that purchase a Starter, Growth, or Enterprise plan have no self-service interface to:

- View their own plan details and seat utilisation
- Invite and manage their members
- Monitor their learners' progress
- Manage sponsored grants (NGOs, schools)
- Update org profile / branding

Everything must be done manually by a Milpress super-admin today. This creates operational bottlenecks and a poor experience for paying org customers.

---

## 2. Goal

Add an **Organization Portal** — a role-scoped view within the existing `milpress-dashboard` Flutter web app — that allows org owners and org admins to self-service their organization, accessible at `/org-login` and `/org/*` routes. Internal admins retain their existing view, unchanged.

---

## 3. What Already Exists (No Re-build Needed)

| Asset | Location | Notes |
|---|---|---|
| `Organization` model | `features/organizations/organization_models.dart` | Complete — plan, seats, branding, status |
| `OrgMember` model | same file | Has `MemberRole.admin \| member`, `MemberStatus` |
| `OrganizationRepository` | `features/organizations/organization_repository.dart` | Full CRUD — fetch org, members, grants, KPIs |
| `SponsoredGrant` model + repo | `features/organizations/sponsored_grant_model.dart` | Bulk create, revoke |
| User Progress widgets | `features/user_progress/widgets/` | `UserDetailsView`, `ProgressSummary`, `DonutChart` etc |
| `ProfilesRepository` | `features/auth/profiles_repository.dart` | Fetch learner profiles |
| `MemberRole` / `OrgPlan` / `SubStatus` enums | `features/subscriptions/subscription_enums.dart` | All DB-aligned |
| Supabase auth | `features/auth/auth_repository.dart` | `signInWithPassword` — same flow org users will use |

---

## 4. What Needs to Be Built

### 4.1 Authentication & Session Layer

**Problem:** The current auth only checks `admin_profiles`. Org users exist in `profiles` (the learner table) and `org_members`. After login we need to detect which "context" the user belongs to.

**New pieces:**

```
features/org_portal/
  auth/
    org_auth_repository.dart       ← login + resolve org context
    org_session_provider.dart      ← holds OrgSession (orgId, role, org object)
    org_auth_guard.dart            ← GoRouter redirect for /org/* routes
```

**`OrgSession` model:**
```dart
class OrgSession {
  final String userId;
  final String orgId;
  final MemberRole role;        // admin | member (members can't access portal)
  final Organization org;       // full org record
}
```

**Login flow:**
1. User hits `/org-login`, enters email + password.
2. `signInWithPassword` via Supabase auth.
3. Look up `org_members` where `user_id = currentUser.id AND role = 'admin' AND status = 'active'`. Also accept if user is `organizations.owner_id`.
4. If found → load the `Organization` record → set `OrgSession` in provider → redirect to `/org/overview`.
5. If not found → show error: "No organization admin account found for this email."
6. If org `status` is `cancelled` or `expired` → show "Your organization subscription is inactive."

**Auth guard:** All `/org/*` routes redirect to `/org-login` if `OrgSession` is null.

---

### 4.2 Router Changes

Add to `router.dart`:

```dart
// Org portal login — outside AppShell
GoRoute(
  path: '/org-login',
  builder: (_, __) => const OrgLoginScreen(),
),

// Org portal shell — scoped nav
ShellRoute(
  builder: (context, state, child) => OrgPortalShell(child: child),
  redirect: orgAuthGuard,    // redirect if no OrgSession
  routes: [
    GoRoute(path: '/org/overview',  builder: (_, __) => const OrgOverviewScreen()),
    GoRoute(path: '/org/members',   builder: (_, __) => const OrgMembersScreen()),
    GoRoute(path: '/org/progress',  builder: (_, __) => const OrgProgressScreen()),
    GoRoute(path: '/org/grants',    builder: (_, __) => const OrgGrantsScreen()),
    GoRoute(path: '/org/settings',  builder: (_, __) => const OrgSettingsScreen()),
  ],
),
```

---

### 4.3 Org Portal Shell (`OrgPortalShell`)

A separate `AppShell`-equivalent with its own sidebar. Lives at:
```
widgets/org_portal_shell.dart
widgets/org_sidebar.dart
```

**Sidebar nav items:**

| Icon | Label | Route | Who Sees It |
|---|---|---|---|
| `dashboard` | Overview | `/org/overview` | All org admins |
| `people_outline` | Members | `/org/members` | All org admins |
| `bar_chart` | Learner Progress | `/org/progress` | All org admins |
| `card_giftcard` | Grants | `/org/grants` | Only if `org.type` is NGO/school OR org has any grants |
| `settings` | Settings | `/org/settings` | All org admins |
| `logout` | Logout | — | All org admins |

**Header:** Shows org name, plan badge (Starter / Growth / Enterprise), and seat pill (`12 / 30 seats`).

---

### 4.4 Screens to Build

#### Screen 1 — Org Login (`/org-login`)
- Email + password fields (same style as existing `AdminLoginScreen`)
- "Sign in to your organization portal" heading
- Link: "Are you a Milpress admin? →" pointing to `/login`
- On success → `/org/overview`

#### Screen 2 — Overview (`/org/overview`)
Reuses `OrganizationRepository.fetchById` + `fetchKpis` scoped to one org.

Widgets:
- **Plan card**: plan name, billing cycle, renewal date, price/month
- **Seat utilisation**: donut chart (reuse existing `DonutChart` widget), `seatsUsed / seatLimit`
- **Member summary**: active, pending, removed counts
- **Active grants**: count of active sponsored grants (if applicable)
- **Quick actions**: "Invite Member", "Download Progress Report" buttons

#### Screen 3 — Members (`/org/members`)
Scoped re-implementation of the existing admin org detail members tab.

Features:
- Table: Name, Email, Role, Status, Joined date
- Invite dialog: enter one or multiple emails → calls `inviteMembers`
- Per-row: change role (admin ↔ member), remove member
- Pending invites shown with "Resend invite" action (trigger re-send email via existing Supabase Edge Function `send-org-invite`)
- Seat limit enforcement: disable "Invite" button + show tooltip if `org.atSeatLimit`

Data: `orgMembersProvider(orgId)` already exists in `organization_repository.dart`.

#### Screen 4 — Learner Progress (`/org/progress`)
Shows progress for all `profiles` where `org_id = session.orgId`.

Two-pane layout (mirror existing `UserDetailsView`):
- **Left**: searchable list of org members (name, email, progress %)
- **Right**: drill-down into selected user's course progress using existing `UserProgressRepository` + widgets

Data providers needed:
- `orgLearnersProvider(orgId)` → query `profiles` where `org_id = ?`
- Reuse existing `UserProgressRepository` for per-user drill-down

#### Screen 5 — Grants (`/org/grants`)
Only shown when applicable. Mirrors the existing admin grants panel, scoped to this org.

Features:
- List: grantee email, status (active/expired/revoked), granted date, valid until
- Bulk invite dialog: paste emails, set expiry date → calls `createSponsoredGrants`
- Per-row: revoke with reason
- Export CSV of grant list

Data: `orgSponsoredGrantsProvider(GrantsQuery(orgId: ...))` already exists.

#### Screen 6 — Settings (`/org/settings`)
- **Org profile**: edit name, contact email, website
- **Branding** (if `customBranding` is enabled for this plan): upload logo, set primary colour
- **Billing info** (read-only): plan, billing cycle, next renewal, amount — with "Contact us to upgrade" CTA
- **Danger zone**: "Contact support to cancel subscription" (no self-serve cancel)

---

### 4.5 Database / RLS Changes

**Current state:** Dashboard uses Supabase with likely a service-role key (bypasses RLS), so org users could read all orgs' data if they log in.

**Required:**

1. **RLS on `organizations`**: org admins can `SELECT` only their own org row.
   ```sql
   CREATE POLICY "org_admin_read_own_org"
     ON organizations FOR SELECT
     USING (
       id IN (
         SELECT org_id FROM org_members
         WHERE user_id = auth.uid()
           AND role = 'admin'
           AND status = 'active'
       )
       OR owner_id = auth.uid()
     );
   ```

2. **RLS on `org_members`**: org admins can read/write members only for their org.
   ```sql
   CREATE POLICY "org_admin_manage_members"
     ON org_members FOR ALL
     USING (
       org_id IN (
         SELECT org_id FROM org_members
         WHERE user_id = auth.uid() AND role = 'admin' AND status = 'active'
       )
     );
   ```

3. **RLS on `profiles`**: org admins can read profiles of learners in their org.
   ```sql
   CREATE POLICY "org_admin_read_org_learners"
     ON profiles FOR SELECT
     USING (
       org_id IN (
         SELECT org_id FROM org_members
         WHERE user_id = auth.uid() AND role = 'admin' AND status = 'active'
       )
     );
   ```

4. **RLS on `sponsored_grants`**: similar scoping to `sponsor_org_id`.

5. **RLS on `user_progress` / `course_progress` / `lesson_progress`**: org admins can read progress of users in their org.

6. **RLS on `org_subscriptions`**: org admins can read their own org's billing row (no write).

> **Important:** The admin dashboard (super-admin users) must still use a service-role Supabase client or have a separate policy (`admin_profiles` role bypass) so existing admin functionality is unaffected. Use `anon` key for org portal users (RLS enforced) vs service key for admins.

---

### 4.6 Two-Client Supabase Strategy

The dashboard currently initialises one `SupabaseClient`. We need two:

| Client | Key | Used by |
|---|---|---|
| `adminClient` | service role key | All existing admin screens |
| `portalClient` | anon key (RLS-enforced) | All `/org/*` screens |

Implementation: add a second initialisation in `secrets.dart` + a `portalSupabaseClientProvider`.

---

### 4.7 Edge Functions / Emails

| Action | Existing? | Notes |
|---|---|---|
| Org member invite email | ✅ `send-org-invite` | Already exists — just call it from org portal too |
| Member removed email | ✅ `send-member-removed` | Already exists |
| Grant revoked email | ✅ `send-grant-revoked` | Already exists |
| Org admin welcome email | ❌ | New: send when Milpress admin first creates the org and sets owner email |

---

## 5. File Structure (New Files Only)

```
milpress-dashboard/lib/
  features/
    org_portal/
      auth/
        org_auth_repository.dart
        org_session_provider.dart
        org_auth_guard.dart
        org_login_screen.dart
      overview/
        org_overview_screen.dart
        widgets/
          org_plan_card.dart
          org_seat_utilisation_card.dart
          org_quick_actions_bar.dart
      members/
        org_members_screen.dart
        widgets/
          org_members_table.dart
          org_invite_dialog.dart
          org_member_role_chip.dart
      progress/
        org_progress_screen.dart
        org_learners_provider.dart
        widgets/
          org_learners_list.dart
      grants/
        org_grants_screen.dart
        widgets/
          org_grants_table.dart
          org_bulk_invite_dialog.dart
      settings/
        org_settings_screen.dart
        widgets/
          org_profile_form.dart
          org_billing_card.dart
  widgets/
    org_portal_shell.dart
    org_sidebar.dart
```

---

## 6. Implementation Order

Work in this order to keep things shippable at each step:

| Step | What | Deliverable |
|---|---|---|
| 1 | DB: Write & apply RLS migration | Org users can't read other orgs' data |
| 2 | Two-client Supabase setup | Admin and portal clients coexist |
| 3 | `OrgSession` + `OrgAuthRepository` + `OrgAuthGuard` | Login works, routes protected |
| 4 | `OrgLoginScreen` + router wiring | `/org-login` renders and redirects correctly |
| 5 | `OrgPortalShell` + `OrgSidebar` | Shell renders, nav works |
| 6 | `OrgOverviewScreen` | First screen org admins see |
| 7 | `OrgMembersScreen` | Core self-service feature |
| 8 | `OrgProgressScreen` | Reuses existing user_progress widgets |
| 9 | `OrgGrantsScreen` | Only for applicable org types |
| 10 | `OrgSettingsScreen` | Polish / branding |
| 11 | Admin: "Set org owner" flow | In existing Organizations screen, ability to assign an owner to an org so they can log in |

---

## 7. Open Questions / Decisions Needed

1. **Separate subdomain?** Should the org portal live at `portal.milpress.com` vs `admin.milpress.com/org-login`? (Affects CORS, Supabase auth redirect URLs, branding.)

2. **Org admin onboarding:** How does an org admin first learn their login? Suggest: when Milpress admin creates an org and sets the owner, a "welcome" email is sent with a "Set your password" link (Supabase magic link / invite).

3. **Self-serve plan upgrade:** Should org admins be able to upgrade their plan themselves (requires Stripe integration for org billing) or always contact Milpress?

4. **Multiple org admins:** An org can have multiple `org_members` with `role = admin`. Any of them should be able to log in to the portal. This is already supported by the data model.

5. **Branding scope:** Which plans get custom branding? Suggest: Growth and above only.

6. **Progress export:** Should org admins be able to export a CSV of learner progress? (Easy to add, needed for school/NGO reporting.)
