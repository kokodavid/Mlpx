-- =============================================================================
-- Migration: 20260628000001_org_portal_rls
-- Purpose:   Row-level security policies for the Organization Portal.
--            Org admins can read/write their own org's data.
--            Platform admins (admin_profiles) bypass all restrictions.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: is the current JWT user a platform admin?
-- Uses SECURITY DEFINER so it can read admin_profiles regardless of caller.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM admin_profiles
    WHERE id = auth.uid()
      AND (is_active IS NULL OR is_active = true)
  );
$$;

-- ---------------------------------------------------------------------------
-- Helper: returns the org_id(s) for which the current user is an admin member.
-- Used in every policy below to avoid repetition.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_admin_org_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT org_id
  FROM org_members
  WHERE user_id = auth.uid()
    AND role    = 'admin'
    AND status  = 'active';
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS on tables (safe to run even if already enabled)
-- ---------------------------------------------------------------------------
ALTER TABLE organizations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members           ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_subscriptions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsored_grants      ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- organizations
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "org_portal_read_own_org"    ON organizations;
DROP POLICY IF EXISTS "org_portal_owner_read"      ON organizations;
DROP POLICY IF EXISTS "platform_admin_read_orgs"   ON organizations;
DROP POLICY IF EXISTS "platform_admin_write_orgs"  ON organizations;

-- Org admins (members with role=admin) can read their org
CREATE POLICY "org_portal_read_own_org"
  ON organizations FOR SELECT
  USING (
    id IN (SELECT my_admin_org_ids())
    OR owner_id = auth.uid()
    OR is_platform_admin()
  );

-- Platform admins can write
CREATE POLICY "platform_admin_write_orgs"
  ON organizations FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

-- Org admins can update their own org (name, branding only — enforced in app)
CREATE POLICY "org_admin_update_own_org"
  ON organizations FOR UPDATE
  USING (
    id IN (SELECT my_admin_org_ids())
    OR owner_id = auth.uid()
  )
  WITH CHECK (
    id IN (SELECT my_admin_org_ids())
    OR owner_id = auth.uid()
  );

-- ---------------------------------------------------------------------------
-- org_members
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "org_portal_read_members"   ON org_members;
DROP POLICY IF EXISTS "org_portal_manage_members" ON org_members;
DROP POLICY IF EXISTS "platform_admin_members"    ON org_members;

-- Org admins can read all members of their org
CREATE POLICY "org_portal_read_members"
  ON org_members FOR SELECT
  USING (
    org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

-- Org admins can insert / update members (invite, role change, remove)
CREATE POLICY "org_portal_manage_members"
  ON org_members FOR INSERT
  WITH CHECK (
    org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

CREATE POLICY "org_portal_update_members"
  ON org_members FOR UPDATE
  USING (
    org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  )
  WITH CHECK (
    org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

-- Platform admins full access
CREATE POLICY "platform_admin_members"
  ON org_members FOR DELETE
  USING (is_platform_admin());

-- ---------------------------------------------------------------------------
-- org_subscriptions
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "org_portal_read_own_sub"  ON org_subscriptions;
DROP POLICY IF EXISTS "platform_admin_subs"      ON org_subscriptions;

CREATE POLICY "org_portal_read_own_sub"
  ON org_subscriptions FOR SELECT
  USING (
    org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

CREATE POLICY "platform_admin_subs"
  ON org_subscriptions FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

-- ---------------------------------------------------------------------------
-- sponsored_grants
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "org_portal_read_grants"   ON sponsored_grants;
DROP POLICY IF EXISTS "org_portal_manage_grants" ON sponsored_grants;
DROP POLICY IF EXISTS "platform_admin_grants"    ON sponsored_grants;

CREATE POLICY "org_portal_read_grants"
  ON sponsored_grants FOR SELECT
  USING (
    sponsor_org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

CREATE POLICY "org_portal_manage_grants"
  ON sponsored_grants FOR INSERT
  WITH CHECK (
    sponsor_org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

CREATE POLICY "org_portal_update_grants"
  ON sponsored_grants FOR UPDATE
  USING (
    sponsor_org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  )
  WITH CHECK (
    sponsor_org_id IN (SELECT my_admin_org_ids())
    OR is_platform_admin()
  );

CREATE POLICY "platform_admin_grants"
  ON sponsored_grants FOR DELETE
  USING (is_platform_admin());

-- ---------------------------------------------------------------------------
-- profiles — org admins can read profiles of learners in their org
-- (Profiles already have RLS from earlier migrations; add org policy here)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "org_admin_read_org_learners" ON profiles;

CREATE POLICY "org_admin_read_org_learners"
  ON profiles FOR SELECT
  USING (
    -- Users can always read their own profile
    id = auth.uid()
    -- Org admins can read profiles of members in their org
    OR org_id IN (SELECT my_admin_org_ids())
    -- Platform admins see all
    OR is_platform_admin()
  );

-- ---------------------------------------------------------------------------
-- Progress tables — org admins can read progress of their org's learners
-- ---------------------------------------------------------------------------

-- course_progress
ALTER TABLE course_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_admin_read_course_progress" ON course_progress;

CREATE POLICY "org_admin_read_course_progress"
  ON course_progress FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IN (
      SELECT id FROM profiles
      WHERE org_id IN (SELECT my_admin_org_ids())
    )
    OR is_platform_admin()
  );

-- module_progress
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_admin_read_module_progress" ON module_progress;

CREATE POLICY "org_admin_read_module_progress"
  ON module_progress FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IN (
      SELECT id FROM profiles
      WHERE org_id IN (SELECT my_admin_org_ids())
    )
    OR is_platform_admin()
  );

-- lesson_completion
ALTER TABLE lesson_completion ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_admin_read_lesson_progress" ON lesson_completion;

CREATE POLICY "org_admin_read_lesson_progress"
  ON lesson_completion FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IN (
      SELECT id FROM profiles
      WHERE org_id IN (SELECT my_admin_org_ids())
    )
    OR is_platform_admin()
  );

-- course_assessment_progress
ALTER TABLE course_assessment_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_admin_read_assessment_progress" ON course_assessment_progress;

CREATE POLICY "org_admin_read_assessment_progress"
  ON course_assessment_progress FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IN (
      SELECT id FROM profiles
      WHERE org_id IN (SELECT my_admin_org_ids())
    )
    OR is_platform_admin()
  );
