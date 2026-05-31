-- =============================================================================
-- Migration: add FK relationships from user-linked columns to public.profiles
--
-- Why:  PostgREST resolves embedded resource selects (e.g. profiles(*)) by
--       following FK constraints inside the *public* schema only.  The original
--       migration wired user_id / learner_id columns to auth.users(id) for
--       referential integrity, but that lives in the auth schema so PostgREST
--       cannot traverse it for JOIN queries.
--
--       Adding a second FK to public.profiles(id) (which is always id-identical
--       to auth.users(id) in Supabase) makes the relationships visible to
--       PostgREST without changing data integrity.
-- =============================================================================

-- subscriptions.user_id  →  profiles.id
ALTER TABLE public.subscriptions
  ADD CONSTRAINT subscriptions_profile_fkey
  FOREIGN KEY (user_id)
  REFERENCES public.profiles(id)
  ON DELETE CASCADE;

-- org_members.user_id  →  profiles.id  (nullable — null until invite redeemed)
ALTER TABLE public.org_members
  ADD CONSTRAINT org_members_profile_fkey
  FOREIGN KEY (user_id)
  REFERENCES public.profiles(id)
  ON DELETE SET NULL;

-- sponsored_grants.learner_id  →  profiles.id  (nullable — null until redeemed)
ALTER TABLE public.sponsored_grants
  ADD CONSTRAINT sponsored_grants_profile_fkey
  FOREIGN KEY (learner_id)
  REFERENCES public.profiles(id)
  ON DELETE SET NULL;

-- organizations.owner_id  →  profiles.id  (for the owner email JOIN)
ALTER TABLE public.organizations
  ADD CONSTRAINT organizations_owner_profile_fkey
  FOREIGN KEY (owner_id)
  REFERENCES public.profiles(id)
  ON DELETE SET NULL;
