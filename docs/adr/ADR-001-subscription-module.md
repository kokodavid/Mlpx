# ADR-001: Subscription Module Architecture

**Status:** Proposed  
**Date:** 2026-04-24  
**Deciders:** Engineering team  
**Relates to:** Individual & organization subscriptions, Stripe billing, feature gating

---

## Context

Millpress is a Flutter/Supabase learning platform with courses, lessons, quizzes, and progress tracking. It currently has no monetization layer. We need to introduce a subscription system that supports:

- **Individual users** — Free, Basic, and Premium tiers with monthly/annual billing
- **Organizations** — Tiered seat-based plans (brackets of users under a single subscription)
- **14-day free trial** on all paid plans
- **Feature gating** for premium courses, full assessments, and progress analytics
- **Stripe** as the payment processor
- **Supabase** (PostgreSQL + Edge Functions) as the backend

The design must integrate cleanly with the existing Riverpod state management, Supabase Auth, and the `profiles` table.

---

## Decision

Adopt a **plan catalog + unified subscriptions table** architecture, with a separate `organizations` entity and a polymorphic `subscriptions` table that can belong to either a user or an org. Stripe is the source of truth for billing state; Supabase holds a synced local mirror updated via webhooks.

---

## Options Considered

### Option A — Separate tables per subscriber type

Two tables: `individual_subscriptions` and `org_subscriptions`, each with their own columns and FK relationships.

| Dimension | Assessment |
|---|---|
| Complexity | Low initial, high long-term |
| Schema duplication | High — shared logic repeated in two places |
| Querying | No single join to "what plan is this user on?" |
| Extensibility | Adding a new subscriber type requires a new table |
| Team familiarity | High |

**Pros:** Simple to start, no polymorphism complexity.  
**Cons:** Feature gating logic must query two tables. Shared fields (status, trial_end, stripe_subscription_id) are duplicated. Adding a new tier type later is expensive. Reporting across subscriber types requires UNIONs.

---

### Option B — Single subscriptions table with subscriber_type enum

One `subscriptions` table with a `subscriber_type` column (`individual` | `organization`) and nullable FKs to both `profiles` and `organizations`.

| Dimension | Assessment |
|---|---|
| Complexity | Medium |
| Schema duplication | None |
| Querying | Single table for all subscription lookups |
| Extensibility | New subscriber types = new enum value + nullable FK |
| Team familiarity | Medium |

**Pros:** Unified querying. Simple RLS. Feature gating reads one table.  
**Cons:** Nullable FKs are a code smell and lose referential integrity enforcement. Queries must always filter by `subscriber_type`. The org membership model still needs a separate table regardless.

---

### Option C — Plan catalog + subscriptions + organizations (recommended)

A normalized `plans` table holds all SKUs (plan name, tier, billing interval, seat limits, feature flags). A unified `subscriptions` table holds one active subscription per subscriber with Stripe state synced. An `organizations` table owns org subscriptions, and `org_memberships` maps users to orgs.

| Dimension | Assessment |
|---|---|
| Complexity | Medium upfront, low long-term |
| Schema duplication | None — feature flags live on the plan row |
| Querying | Single join path: user → subscription → plan → features |
| Extensibility | New plans = new row in `plans`. New features = new column on `plans` |
| Stripe alignment | Plans map 1:1 to Stripe Price IDs |
| Team familiarity | Medium |

**Pros:** Feature flags are data, not code. Plans map cleanly to Stripe products/prices. Single entitlement check regardless of subscriber type. Reporting is straightforward. New billing intervals or tiers don't change application logic.  
**Cons:** Slightly more initial setup. Requires an `organizations` table which doesn't currently exist.

---

## Trade-off Analysis

The core tension is between **setup simplicity (A/B)** and **long-term maintainability (C)**. Given that this is a greenfield subscription system being built from scratch, the cost of Option C's upfront schema design is low relative to the cost of migrating from A or B later when pricing tiers change (and they always change). Option C is also the closest match to how Stripe models products and prices natively, which makes webhook syncing straightforward.

The nullable FK concern in Option B is a real integrity risk — a deleted org could leave orphan subscription rows without careful cascade logic. Option C avoids this by keeping org and individual subscriptions structurally separate while sharing the subscription + plan lookup path.

---

## Recommended Architecture (Option C)

### 1. Supabase Database Schema

#### `plans` — SKU catalog
```sql
create table plans (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,                          -- "Basic Monthly", "Org Growth Annual"
  slug             text unique not null,                   -- "basic_monthly", "org_growth_annual"
  subscriber_type  text not null check (subscriber_type in ('individual', 'organization')),
  tier             text not null check (tier in ('free', 'basic', 'premium', 'org_starter', 'org_growth', 'org_business', 'org_enterprise')),
  billing_interval text check (billing_interval in ('monthly', 'annual', 'lifetime')),
  price_usd_cents  integer not null default 0,
  stripe_price_id  text unique,                            -- links to Stripe Price object
  seat_min         integer,                                -- org plans: lower bracket bound
  seat_max         integer,                                -- org plans: upper bracket bound (null = unlimited)
  -- feature flags
  has_premium_courses    boolean not null default false,
  has_full_assessments   boolean not null default false,
  has_analytics          boolean not null default false,
  has_offline_downloads  boolean not null default false,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);
```

#### `organizations`
```sql
create table organizations (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  slug         text unique not null,
  owner_id     uuid not null references auth.users(id) on delete restrict,
  seat_limit   integer not null default 10,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
```

#### `subscriptions` — unified subscription record
```sql
create table subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  -- exactly one of these is set
  user_id                 uuid references auth.users(id) on delete cascade,
  org_id                  uuid references organizations(id) on delete cascade,
  plan_id                 uuid not null references plans(id),
  -- status mirrors Stripe subscription status
  status                  text not null check (status in (
                            'trialing', 'active', 'past_due',
                            'canceled', 'unpaid', 'incomplete'
                          )),
  trial_start             timestamptz,
  trial_end               timestamptz,
  current_period_start    timestamptz,
  current_period_end      timestamptz,
  cancel_at_period_end    boolean not null default false,
  canceled_at             timestamptz,
  -- stripe references
  stripe_customer_id      text,
  stripe_subscription_id  text unique,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  -- enforce exactly one subscriber type
  constraint chk_one_subscriber check (
    (user_id is not null and org_id is null) or
    (user_id is null and org_id is not null)
  )
);

create index on subscriptions (user_id) where user_id is not null;
create index on subscriptions (org_id) where org_id is not null;
create index on subscriptions (stripe_subscription_id);
```

#### `org_memberships` — user ↔ org mapping
```sql
create type org_role as enum ('owner', 'admin', 'member');
create type membership_status as enum ('active', 'invited', 'suspended', 'removed');

create table org_memberships (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references organizations(id) on delete cascade,
  user_id    uuid references auth.users(id) on delete cascade,
  email      text,                                         -- for pending invites before signup
  role       org_role not null default 'member',
  status     membership_status not null default 'invited',
  invited_by uuid references auth.users(id),
  joined_at  timestamptz,
  created_at timestamptz not null default now(),
  constraint chk_user_or_email check (user_id is not null or email is not null),
  unique (org_id, user_id)
);

create index on org_memberships (user_id) where user_id is not null;
create index on org_memberships (org_id, status);
```

#### `stripe_customers` — customer ID registry
```sql
create table stripe_customers (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid unique references auth.users(id) on delete cascade,
  org_id             uuid unique references organizations(id) on delete cascade,
  stripe_customer_id text unique not null,
  created_at         timestamptz not null default now(),
  constraint chk_one_entity check (
    (user_id is not null and org_id is null) or
    (user_id is null and org_id is not null)
  )
);
```

---

### 2. Plan Catalog Seed Data

```sql
-- Individual plans
insert into plans (name, slug, subscriber_type, tier, billing_interval, price_usd_cents, has_premium_courses, has_full_assessments, has_analytics) values
  ('Free',            'free',             'individual', 'free',    null,      0,    false, false, false),
  ('Basic Monthly',   'basic_monthly',    'individual', 'basic',   'monthly', 999,  true,  false, false),
  ('Basic Annual',    'basic_annual',     'individual', 'basic',   'annual',  9999, true,  false, false),
  ('Premium Monthly', 'premium_monthly',  'individual', 'premium', 'monthly', 1999, true,  true,  true),
  ('Premium Annual',  'premium_annual',   'individual', 'premium', 'annual',  19999,true,  true,  true);

-- Organization plans (tiered seats)
insert into plans (name, slug, subscriber_type, tier, billing_interval, price_usd_cents, seat_min, seat_max, has_premium_courses, has_full_assessments, has_analytics) values
  ('Org Starter Monthly', 'org_starter_monthly', 'organization', 'org_starter',  'monthly', 4900,   1,  10,  true, true, true),
  ('Org Starter Annual',  'org_starter_annual',  'organization', 'org_starter',  'annual',  49000,  1,  10,  true, true, true),
  ('Org Growth Monthly',  'org_growth_monthly',  'organization', 'org_growth',   'monthly', 14900,  11, 50,  true, true, true),
  ('Org Growth Annual',   'org_growth_annual',   'organization', 'org_growth',   'annual',  149000, 11, 50,  true, true, true),
  ('Org Business Monthly','org_business_monthly','organization', 'org_business', 'monthly', 34900,  51, 200, true, true, true),
  ('Org Business Annual', 'org_business_annual', 'organization', 'org_business', 'annual',  349000, 51, 200, true, true, true);
```

---

### 3. Row Level Security (RLS)

```sql
-- Subscriptions: users can read their own; org members can read their org's
alter table subscriptions enable row level security;

create policy "Users can read own subscription"
  on subscriptions for select
  using (user_id = auth.uid());

create policy "Org members can read org subscription"
  on subscriptions for select
  using (
    org_id in (
      select org_id from org_memberships
      where user_id = auth.uid() and status = 'active'
    )
  );

-- Only service role (webhook handler) can write subscriptions
create policy "Service role writes subscriptions"
  on subscriptions for all
  using (auth.role() = 'service_role');

-- Org memberships
alter table org_memberships enable row level security;

create policy "Members can view their org memberships"
  on org_memberships for select
  using (
    org_id in (
      select org_id from org_memberships
      where user_id = auth.uid() and status = 'active'
    )
  );

create policy "Org admins can manage memberships"
  on org_memberships for all
  using (
    org_id in (
      select org_id from org_memberships
      where user_id = auth.uid()
        and role in ('owner', 'admin')
        and status = 'active'
    )
  );
```

---

### 4. Stripe Integration

#### Product / Price structure in Stripe Dashboard
Each row in `plans` with a non-null `stripe_price_id` maps to one Stripe Price object under a parent Stripe Product. Recommended product grouping:

```
Product: "Millpress Individual"
  ├── Price: Basic Monthly  → plans.stripe_price_id = "price_xxx"
  ├── Price: Basic Annual   → plans.stripe_price_id = "price_xxx"
  ├── Price: Premium Monthly
  └── Price: Premium Annual

Product: "Millpress Organization"
  ├── Price: Org Starter Monthly
  ├── Price: Org Starter Annual
  ├── Price: Org Growth Monthly
  └── ... etc
```

#### Checkout flow
1. Flutter app calls a Supabase Edge Function: `POST /functions/v1/create-checkout-session`
2. Edge function creates (or retrieves) a Stripe Customer for the user/org via `stripe_customers` table
3. Creates a `checkout.session` with:
   - `mode: 'subscription'`
   - `subscription_data.trial_period_days: 14` (for all paid plans)
   - `success_url` and `cancel_url` pointing back to the app via deep link
4. Returns the Checkout URL → Flutter opens it in an in-app web view or the system browser

#### Webhook sync (Edge Function: `POST /functions/v1/stripe-webhook`)
The webhook handler uses the Supabase service role key to write to `subscriptions`. Events to handle:

| Stripe event | Action |
|---|---|
| `checkout.session.completed` | Create subscription row, set `status = 'trialing'` or `'active'` |
| `customer.subscription.updated` | Update status, period dates, `cancel_at_period_end` |
| `customer.subscription.deleted` | Set `status = 'canceled'`, set `canceled_at` |
| `invoice.payment_failed` | Set `status = 'past_due'` |
| `invoice.payment_succeeded` | Reset `status = 'active'`, update period dates |
| `customer.subscription.trial_will_end` | (Optional) Trigger in-app reminder push |

All events are verified with `stripe.webhooks.constructEvent()` using the webhook signing secret.

---

### 5. Feature Gating in Flutter/Riverpod

#### Entitlement model
```dart
// lib/features/subscription/models/entitlement.dart
@freezed
class Entitlement with _$Entitlement {
  const factory Entitlement({
    required String planSlug,
    required String tier,
    required bool isActive,          // status in ['trialing', 'active']
    required bool hasPremiumCourses,
    required bool hasFullAssessments,
    required bool hasAnalytics,
    DateTime? trialEnd,
    DateTime? currentPeriodEnd,
    OrgInfo? org,                    // non-null if user is on an org plan
  }) = _Entitlement;

  factory Entitlement.free() => const Entitlement(
    planSlug: 'free',
    tier: 'free',
    isActive: true,
    hasPremiumCourses: false,
    hasFullAssessments: false,
    hasAnalytics: false,
  );
}
```

#### Subscription provider
```dart
// lib/features/subscription/providers/subscription_provider.dart
@riverpod
Future<Entitlement> entitlement(EntitlementRef ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return Entitlement.free();

  // 1. Check if user has a direct subscription
  final directSub = await SubscriptionService.getActiveForUser(user.id);
  if (directSub != null) return directSub.toEntitlement();

  // 2. Check if user belongs to an org with an active subscription
  final orgSub = await SubscriptionService.getActiveForUserOrg(user.id);
  if (orgSub != null) return orgSub.toEntitlement();

  // 3. Default: free tier
  return Entitlement.free();
}
```

#### Gate widget
```dart
// lib/features/subscription/widgets/entitlement_gate.dart
class EntitlementGate extends ConsumerWidget {
  final bool Function(Entitlement) check;
  final Widget child;
  final Widget? fallback;

  const EntitlementGate({
    required this.check,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    return entitlement.when(
      data: (e) => check(e) ? child : (fallback ?? const UpgradePrompt()),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

// Usage:
EntitlementGate(
  check: (e) => e.hasPremiumCourses,
  child: PremiumCourseContent(),
  fallback: LockedCourseCard(onUpgrade: () => router.push('/subscribe')),
)
```

---

### 6. Organization Management

#### Seat enforcement
```sql
-- Prevent exceeding seat limit on insert
create or replace function check_seat_limit()
returns trigger as $$
declare
  current_seats integer;
  seat_limit    integer;
begin
  select count(*) into current_seats
  from org_memberships
  where org_id = new.org_id and status = 'active';

  select o.seat_limit into seat_limit
  from organizations o where o.id = new.org_id;

  if current_seats >= seat_limit then
    raise exception 'Seat limit reached. Upgrade your plan to add more members.';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger enforce_seat_limit
  before insert on org_memberships
  for each row execute function check_seat_limit();
```

#### Seat limit sync from Stripe
When an org upgrades from `org_starter` (max 10) to `org_growth` (max 50), the webhook handler updates `organizations.seat_limit` to match the new plan's `seat_max`.

#### Invitation flow
1. Org admin calls Edge Function: `POST /functions/v1/invite-member` with `{email, org_id, role}`
2. Creates `org_memberships` row with `status = 'invited'`, `user_id = null`, `email = email`
3. Sends invite email via Supabase Auth `inviteUserByEmail()` with `options.data = { org_id }`
4. On signup/login, a Supabase Auth hook resolves the pending invite: matches email → sets `user_id`, changes `status = 'active'`

---

### 7. File Structure

```
lib/
└── features/
    └── subscription/
        ├── models/
        │   ├── plan.dart               # Plan model (mirrors plans table)
        │   ├── subscription.dart       # Subscription model
        │   ├── entitlement.dart        # Derived entitlement (feature flags)
        │   └── org_membership.dart     # OrgMembership model
        ├── services/
        │   ├── subscription_service.dart   # Supabase queries
        │   └── checkout_service.dart       # Calls Edge Functions
        ├── providers/
        │   ├── entitlement_provider.dart   # Main entitlement provider
        │   ├── subscription_provider.dart  # Raw subscription state
        │   └── org_provider.dart           # Org + membership state
        ├── screens/
        │   ├── paywall_screen.dart         # Upgrade prompt / plan picker
        │   ├── subscription_screen.dart    # Current plan, manage billing
        │   └── org_management_screen.dart  # Invite/manage members
        └── widgets/
            ├── entitlement_gate.dart       # Feature gate widget
            ├── plan_card.dart              # Plan display card
            └── upgrade_prompt.dart         # Inline upsell widget

supabase/
└── functions/
    ├── create-checkout-session/
    │   └── index.ts
    ├── stripe-webhook/
    │   └── index.ts
    └── invite-member/
        └── index.ts
```

---

## Consequences

**What becomes easier:**
- Feature gating is a single widget wrapper (`EntitlementGate`) anywhere in the UI
- Adding a new plan (e.g., a student discount) is a new row in `plans` + a new Stripe Price — no application code change
- Reporting subscription revenue by tier is a simple SQL join across `subscriptions` and `plans`
- Org seat upgrades automatically unlock more users without code changes

**What becomes harder:**
- Initial setup requires Stripe product/price configuration and webhook endpoint deployment
- The `organizations` entity is new infrastructure — org creation, slug management, and ownership transfer need to be built
- Edge Function cold-start latency can affect checkout UX; mitigate with Stripe's hosted Checkout page

**What we'll need to revisit:**
- Enterprise org pricing (above 200 seats) will likely need custom/quote-based pricing outside of Stripe's standard Checkout — design a `contact_sales` flow
- Currency localization (KES, NGN, etc.) if targeting African markets with Stripe; consider Paystack as an alternative gateway for local payment methods
- Grace period behavior on `past_due` — define how long before content is locked after a failed payment

---

## Action Items

1. [ ] Create `plans`, `subscriptions`, `organizations`, `org_memberships`, `stripe_customers` tables in Supabase
2. [ ] Seed `plans` table with all individual and org SKUs
3. [ ] Configure Stripe products and prices; store `stripe_price_id` values back in `plans` table
4. [ ] Implement `create-checkout-session` Edge Function with 14-day trial support
5. [ ] Implement `stripe-webhook` Edge Function with event verification and subscription sync
6. [ ] Implement `invite-member` Edge Function and Auth hook for invite resolution
7. [ ] Build `Entitlement`, `Plan`, `Subscription`, `OrgMembership` Dart models with Freezed
8. [ ] Build `entitlementProvider` and `EntitlementGate` widget
9. [ ] Apply `EntitlementGate` to premium courses, assessments, and analytics screens
10. [ ] Build `PaywallScreen` and `OrgManagementScreen`
11. [ ] Write RLS policies and seat-limit trigger in Supabase
12. [ ] Add `subscription_status` to deep link routing so the app handles Stripe redirect
