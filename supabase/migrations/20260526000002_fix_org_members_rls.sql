-- =============================================================================
-- Migration: fix infinite-recursion in org_members RLS policies
--
-- Root cause: the "Org admins can manage their members" policy on org_members
-- queries org_members itself to check the caller's admin role.  That subquery
-- triggers the same policy → infinite recursion (Postgres error 42P17).
--
-- Fix: extract the check into a SECURITY DEFINER function which runs as the
-- function owner (bypassing RLS) so the subquery never triggers policies again.
-- Then rebuild every policy that referenced org_members from within a policy.
-- =============================================================================

-- -----------------------------------------------------------------------
-- 1. Helper: is_org_admin(org_id)  — SECURITY DEFINER bypasses RLS
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_org_admin(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.org_members
    WHERE org_id  = p_org_id
      AND user_id = auth.uid()
      AND role    = 'admin'
      AND status  = 'active'
  );
$$;

-- -----------------------------------------------------------------------
-- 2. Rebuild org_members policies (drop the recursive one, replace it)
-- -----------------------------------------------------------------------
DROP POLICY IF EXISTS "Org admins can manage their members" ON public.org_members;

CREATE POLICY "Org admins can manage their members"
  ON public.org_members FOR ALL
  USING      (is_org_admin(org_members.org_id))
  WITH CHECK (is_org_admin(org_members.org_id));

-- -----------------------------------------------------------------------
-- 3. Rebuild organizations policies that queried org_members directly
--    (those subqueries also trigger org_members RLS → same recursion path)
-- -----------------------------------------------------------------------
DROP POLICY IF EXISTS "Org members can view their organisation" ON public.organizations;

CREATE POLICY "Org members can view their organisation"
  ON public.organizations FOR SELECT
  USING (
    is_admin()
    OR owner_id = auth.uid()
    OR EXISTS (
         SELECT 1 FROM public.org_members
         WHERE org_id  = organizations.id
           AND user_id = auth.uid()
           AND status  = 'active'
       )
  );

-- -----------------------------------------------------------------------
-- 4. Rebuild org_subscriptions policy (also queried org_members directly)
-- -----------------------------------------------------------------------
DROP POLICY IF EXISTS "Org members can view their org subscription" ON public.org_subscriptions;

CREATE POLICY "Org members can view their org subscription"
  ON public.org_subscriptions FOR SELECT
  USING (
    is_admin()
    OR EXISTS (
         SELECT 1 FROM public.org_members
         WHERE org_id  = org_subscriptions.org_id
           AND user_id = auth.uid()
           AND status  = 'active'
       )
  );

-- -----------------------------------------------------------------------
-- 5. Rebuild sponsored_grants policy (also queried org_members directly)
-- -----------------------------------------------------------------------
DROP POLICY IF EXISTS "Org admins can manage their grants" ON public.sponsored_grants;

CREATE POLICY "Org admins can manage their grants"
  ON public.sponsored_grants FOR ALL
  USING      (is_admin() OR is_org_admin(sponsored_grants.sponsor_org_id))
  WITH CHECK (is_admin() OR is_org_admin(sponsored_grants.sponsor_org_id));
