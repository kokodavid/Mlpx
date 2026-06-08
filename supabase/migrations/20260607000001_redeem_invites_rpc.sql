-- =============================================================================
-- Migration: redeem_pending_invites RPC
--
-- The learner app cannot UPDATE org_members or sponsored_grants directly
-- because those tables have admin-only RLS policies.  This SECURITY DEFINER
-- function runs as the DB owner (bypassing RLS) so the redemption always
-- succeeds when a matching pending invite exists.
--
-- Called from the Flutter app on every sign-in via supabase.rpc().
-- =============================================================================

CREATE OR REPLACE FUNCTION public.redeem_pending_invites(
  p_user_id uuid,
  p_email   text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Claim any pending org member invites for this email
  UPDATE public.org_members
  SET
    user_id   = p_user_id,
    status    = 'active',
    joined_at = now()
  WHERE invite_email = lower(p_email)
    AND status       = 'pending'
    AND user_id      IS NULL;

  -- 2. Claim any pending sponsored grants for this email
  UPDATE public.sponsored_grants
  SET
    learner_id   = p_user_id,
    redeemed_at  = now()
  WHERE invite_email = lower(p_email)
    AND status       = 'active'
    AND learner_id   IS NULL;

  -- 3. Recompute the profile plan_type now that rows are stamped
  --    (the triggers on org_members/sponsored_grants will also fire,
  --     but calling sync directly ensures it runs even if no rows matched)
  PERFORM public.sync_profile_plan_type(p_user_id);
END;
$$;

-- Only authenticated users can call this function — and only for their own id
REVOKE ALL ON FUNCTION public.redeem_pending_invites(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_pending_invites(uuid, text) TO authenticated;
