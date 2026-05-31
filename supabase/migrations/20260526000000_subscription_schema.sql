-- =============================================================================
-- MILPRESS SUBSCRIPTION SCHEMA
-- Migration: 20260526000000_subscription_schema.sql
-- Description: Introduces full subscription infrastructure — individual plans,
--              organisation plans, sponsored access, and feature-gating support.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. HELPER: check if the calling user is an active admin
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM admin_profiles
    WHERE id = auth.uid()
      AND is_active = true
  );
$$;


-- -----------------------------------------------------------------------------
-- 1. ENUMS
-- -----------------------------------------------------------------------------

-- Individual learner plan
CREATE TYPE plan_type AS ENUM (
  'free',        -- default, Beginner content only
  'premium',     -- $4.99/mo — all content + features
  'sponsored'    -- granted by an organisation, same access as premium
);

-- Organisation subscription tier
CREATE TYPE org_plan AS ENUM (
  'starter',     -- up to 30 seats,  $129.99/mo
  'growth',      -- up to 150 seats, $699.99/mo
  'enterprise'   -- unlimited seats, custom pricing
);

-- Shared subscription lifecycle status
CREATE TYPE sub_status AS ENUM (
  'trialing',
  'active',
  'past_due',
  'cancelled',
  'expired'
);

-- Billing cadence
CREATE TYPE billing_cycle AS ENUM (
  'monthly',
  'annual'
);

-- Organisation category (for sponsored-access filtering)
CREATE TYPE org_type AS ENUM (
  'school',
  'ngo',
  'employer',
  'government',
  'community'
);

-- Role inside an organisation
CREATE TYPE member_role AS ENUM (
  'admin',   -- can manage members & sponsored grants
  'member'   -- regular seat holder
);

-- Membership lifecycle
CREATE TYPE member_status AS ENUM (
  'pending',   -- invite sent, not yet accepted
  'active',
  'removed'
);

-- Sponsored grant lifecycle
CREATE TYPE grant_status AS ENUM (
  'active',
  'expired',
  'revoked'
);


-- -----------------------------------------------------------------------------
-- 2. ORGANISATIONS
--    Must be created before subscriptions & grants because both reference it.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organizations (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text        NOT NULL,
  type             org_type    NOT NULL,
  plan             org_plan    NOT NULL DEFAULT 'starter',
  seat_limit       int,                          -- NULL = unlimited (enterprise)
  seats_used       int         NOT NULL DEFAULT 0,
  owner_id         uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  custom_branding  jsonb,                        -- enterprise only
  status           sub_status  NOT NULL DEFAULT 'active',
  notes            text,                         -- internal admin notes
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT seats_used_non_negative CHECK (seats_used >= 0),
  CONSTRAINT seat_limit_positive     CHECK (seat_limit IS NULL OR seat_limit > 0)
);

-- Auto-update updated_at on organisations
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();


-- -----------------------------------------------------------------------------
-- 3. INDIVIDUAL LEARNER SUBSCRIPTIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan                 plan_type   NOT NULL DEFAULT 'premium',
  status               sub_status  NOT NULL DEFAULT 'active',
  billing_cycle        billing_cycle NOT NULL DEFAULT 'monthly',
  current_period_start timestamptz NOT NULL DEFAULT now(),
  current_period_end   timestamptz NOT NULL,
  payment_provider     text,                          -- 'stripe' | 'paystack'
  external_sub_id      text,                          -- provider's subscription ID
  external_customer_id text,                          -- provider's customer ID
  cancelled_at         timestamptz,
  cancel_at_period_end boolean     NOT NULL DEFAULT false,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),

  -- One active subscription per user at a time
  CONSTRAINT one_active_sub_per_user UNIQUE (user_id, status)
    DEFERRABLE INITIALLY DEFERRED
);

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Index for fast lookups by user
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status  ON subscriptions(status);


-- -----------------------------------------------------------------------------
-- 4. ORGANISATION SUBSCRIPTIONS
--    Billing record at the organisation level (separate from seat holders).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS org_subscriptions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id               uuid          NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan                 org_plan      NOT NULL,
  status               sub_status    NOT NULL DEFAULT 'active',
  billing_cycle        billing_cycle NOT NULL DEFAULT 'monthly',
  amount_usd           numeric(10,2),               -- NULL for enterprise (custom)
  current_period_start timestamptz   NOT NULL DEFAULT now(),
  current_period_end   timestamptz,                 -- NULL for enterprise
  payment_provider     text,
  external_sub_id      text,
  external_customer_id text,
  cancelled_at         timestamptz,
  cancel_at_period_end boolean       NOT NULL DEFAULT false,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  updated_at           timestamptz   NOT NULL DEFAULT now()
);

CREATE TRIGGER org_subscriptions_updated_at
  BEFORE UPDATE ON org_subscriptions
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE INDEX idx_org_subscriptions_org_id ON org_subscriptions(org_id);


-- -----------------------------------------------------------------------------
-- 5. ORGANISATION MEMBERS
--    Links a Supabase auth user to an organisation as a seat holder.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS org_members (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid          NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id     uuid          REFERENCES auth.users(id) ON DELETE SET NULL,  -- NULL until invite redeemed
  invite_email text         NOT NULL,
  role        member_role   NOT NULL DEFAULT 'member',
  status      member_status NOT NULL DEFAULT 'pending',
  invited_at  timestamptz   NOT NULL DEFAULT now(),
  joined_at   timestamptz,
  removed_at  timestamptz,

  CONSTRAINT org_member_unique UNIQUE (org_id, invite_email)
);

CREATE INDEX idx_org_members_org_id  ON org_members(org_id);
CREATE INDEX idx_org_members_user_id ON org_members(user_id);

-- Trigger: keep seats_used accurate automatically
CREATE OR REPLACE FUNCTION sync_seats_used()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Recalculate seats_used for the affected org
  UPDATE organizations
  SET seats_used = (
    SELECT COUNT(*) FROM org_members
    WHERE org_id = COALESCE(NEW.org_id, OLD.org_id)
      AND status = 'active'
  )
  WHERE id = COALESCE(NEW.org_id, OLD.org_id);

  RETURN NEW;
END;
$$;

CREATE TRIGGER org_members_sync_seats
  AFTER INSERT OR UPDATE OR DELETE ON org_members
  FOR EACH ROW EXECUTE FUNCTION sync_seats_used();

-- Trigger: enforce seat limit before a member becomes active
CREATE OR REPLACE FUNCTION enforce_seat_limit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_limit int;
  v_used  int;
BEGIN
  -- Only check when a member is being set to 'active'
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;
  -- If OLD status is already active, this is just an update — no seat consumed
  IF TG_OP = 'UPDATE' AND OLD.status = 'active' THEN
    RETURN NEW;
  END IF;

  SELECT seat_limit, seats_used
    INTO v_limit, v_used
    FROM organizations
   WHERE id = NEW.org_id;

  IF v_limit IS NOT NULL AND v_used >= v_limit THEN
    RAISE EXCEPTION 'Organisation seat limit reached (limit: %, used: %)', v_limit, v_used;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER org_members_enforce_limit
  BEFORE INSERT OR UPDATE ON org_members
  FOR EACH ROW EXECUTE FUNCTION enforce_seat_limit();


-- -----------------------------------------------------------------------------
-- 6. SPONSORED GRANTS
--    An organisation sponsors N learners with Premium access.
--    The learner may or may not have signed up yet (invite_email covers both).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sponsored_grants (
  id               uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsor_org_id   uuid         NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  learner_id       uuid         REFERENCES auth.users(id) ON DELETE SET NULL,  -- NULL until redeemed
  invite_email     text         NOT NULL,
  grant_type       plan_type    NOT NULL DEFAULT 'premium',
  status           grant_status NOT NULL DEFAULT 'active',
  valid_from       timestamptz  NOT NULL DEFAULT now(),
  valid_until      timestamptz,                   -- NULL = open-ended
  redeemed_at      timestamptz,
  revoked_at       timestamptz,
  revoke_reason    text,
  created_at       timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT one_active_grant_per_email_per_org UNIQUE (sponsor_org_id, invite_email)
);

CREATE INDEX idx_sponsored_grants_sponsor_org ON sponsored_grants(sponsor_org_id);
CREATE INDEX idx_sponsored_grants_learner_id  ON sponsored_grants(learner_id);
CREATE INDEX idx_sponsored_grants_email       ON sponsored_grants(invite_email);


-- -----------------------------------------------------------------------------
-- 7. ALTER PROFILES
--    Add subscription-awareness columns to the existing profiles table.
--    Defaults preserve current behaviour — all existing users remain 'free'.
-- -----------------------------------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS plan_type    plan_type   NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS org_id       uuid        REFERENCES organizations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS sponsored_by uuid        REFERENCES organizations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_plan_type ON profiles(plan_type);
CREATE INDEX IF NOT EXISTS idx_profiles_org_id    ON profiles(org_id);


-- -----------------------------------------------------------------------------
-- 8. ENTITLEMENT SYNC
--    Keep profiles.plan_type in sync whenever a subscription or grant changes.
--    The learner app can read a single column rather than joining multiple tables.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_profile_plan_type(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan plan_type := 'free';
BEGIN
  -- 1. Check active individual premium subscription
  IF EXISTS (
    SELECT 1 FROM subscriptions
    WHERE user_id = p_user_id
      AND status = 'active'
      AND plan = 'premium'
      AND current_period_end > now()
  ) THEN
    v_plan := 'premium';

  -- 2. Check active org membership (org members get premium content)
  ELSIF EXISTS (
    SELECT 1 FROM org_members om
    JOIN organizations o ON o.id = om.org_id
    WHERE om.user_id = p_user_id
      AND om.status = 'active'
      AND o.status = 'active'
  ) THEN
    v_plan := 'premium';

  -- 3. Check active sponsored grant
  ELSIF EXISTS (
    SELECT 1 FROM sponsored_grants
    WHERE learner_id = p_user_id
      AND status = 'active'
      AND (valid_until IS NULL OR valid_until > now())
  ) THEN
    v_plan := 'sponsored';
  END IF;

  UPDATE profiles SET plan_type = v_plan WHERE id = p_user_id;
END;
$$;

-- Trigger on subscriptions
CREATE OR REPLACE FUNCTION on_subscription_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM sync_profile_plan_type(COALESCE(NEW.user_id, OLD.user_id));
  RETURN NEW;
END;
$$;

CREATE TRIGGER subscriptions_sync_profile
  AFTER INSERT OR UPDATE OR DELETE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION on_subscription_change();

-- Trigger on org_members
CREATE OR REPLACE FUNCTION on_org_member_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF COALESCE(NEW.user_id, OLD.user_id) IS NOT NULL THEN
    PERFORM sync_profile_plan_type(COALESCE(NEW.user_id, OLD.user_id));
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER org_members_sync_profile
  AFTER INSERT OR UPDATE OR DELETE ON org_members
  FOR EACH ROW EXECUTE FUNCTION on_org_member_change();

-- Trigger on sponsored_grants
CREATE OR REPLACE FUNCTION on_sponsored_grant_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF COALESCE(NEW.learner_id, OLD.learner_id) IS NOT NULL THEN
    PERFORM sync_profile_plan_type(COALESCE(NEW.learner_id, OLD.learner_id));
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER sponsored_grants_sync_profile
  AFTER INSERT OR UPDATE OR DELETE ON sponsored_grants
  FOR EACH ROW EXECUTE FUNCTION on_sponsored_grant_change();


-- -----------------------------------------------------------------------------
-- 9. ROW LEVEL SECURITY
-- -----------------------------------------------------------------------------

-- organizations ---------------------------------------------------------------
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can do everything on organizations"
  ON organizations FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Org owners can view their own org"
  ON organizations FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Org members can view their org"
  ON organizations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM org_members
      WHERE org_id = organizations.id
        AND user_id = auth.uid()
        AND status = 'active'
    )
  );

-- subscriptions ---------------------------------------------------------------
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can do everything on subscriptions"
  ON subscriptions FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Users can view their own subscription"
  ON subscriptions FOR SELECT
  USING (user_id = auth.uid());

-- org_subscriptions -----------------------------------------------------------
ALTER TABLE org_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can do everything on org_subscriptions"
  ON org_subscriptions FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Org owners can view their org billing"
  ON org_subscriptions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = org_subscriptions.org_id
        AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Org admins can view their org billing"
  ON org_subscriptions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM org_members
      WHERE org_id = org_subscriptions.org_id
        AND user_id = auth.uid()
        AND role = 'admin'
        AND status = 'active'
    )
  );

-- org_members -----------------------------------------------------------------
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can do everything on org_members"
  ON org_members FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Org admins can manage their members"
  ON org_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM org_members om
      WHERE om.org_id = org_members.org_id
        AND om.user_id = auth.uid()
        AND om.role = 'admin'
        AND om.status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM org_members om
      WHERE om.org_id = org_members.org_id
        AND om.user_id = auth.uid()
        AND om.role = 'admin'
        AND om.status = 'active'
    )
  );

CREATE POLICY "Members can view their own membership"
  ON org_members FOR SELECT
  USING (user_id = auth.uid());

-- sponsored_grants ------------------------------------------------------------
ALTER TABLE sponsored_grants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can do everything on sponsored_grants"
  ON sponsored_grants FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Org admins can manage grants for their org"
  ON sponsored_grants FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM org_members
      WHERE org_id = sponsored_grants.sponsor_org_id
        AND user_id = auth.uid()
        AND role = 'admin'
        AND status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM org_members
      WHERE org_id = sponsored_grants.sponsor_org_id
        AND user_id = auth.uid()
        AND role = 'admin'
        AND status = 'active'
    )
  );

CREATE POLICY "Learners can view their own grants"
  ON sponsored_grants FOR SELECT
  USING (learner_id = auth.uid());


-- -----------------------------------------------------------------------------
-- 10. COMMENTS (documentation in the DB itself)
-- -----------------------------------------------------------------------------
COMMENT ON TABLE organizations       IS 'Organisation accounts — schools, NGOs, employers, etc.';
COMMENT ON TABLE subscriptions       IS 'Individual learner Premium subscriptions';
COMMENT ON TABLE org_subscriptions   IS 'Billing record for organisation plans (Starter/Growth/Enterprise)';
COMMENT ON TABLE org_members         IS 'Seat holders within an organisation';
COMMENT ON TABLE sponsored_grants    IS 'Premium access grants issued by a sponsor org to individual learners';

COMMENT ON COLUMN profiles.plan_type    IS 'Denormalised effective plan — kept in sync by triggers. Read this for feature gating.';
COMMENT ON COLUMN profiles.org_id       IS 'Set when the user is an active org member';
COMMENT ON COLUMN profiles.sponsored_by IS 'Set when the user has an active sponsored grant';

COMMENT ON FUNCTION sync_profile_plan_type IS 'Recomputes and writes profiles.plan_type for a given user. Priority: premium sub > org member > sponsored grant > free.';
COMMENT ON FUNCTION is_admin              IS 'Returns true if the calling auth.uid() is an active admin in admin_profiles.';
