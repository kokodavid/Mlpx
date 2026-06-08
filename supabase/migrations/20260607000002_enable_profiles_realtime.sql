-- =============================================================================
-- Enable Realtime on the profiles table so the learner app can subscribe
-- to plan_type changes (org removal, grant revocation, etc.)
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
