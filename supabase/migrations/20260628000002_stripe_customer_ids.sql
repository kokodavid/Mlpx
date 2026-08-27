-- =============================================================================
-- Migration: 20260628000002_stripe_customer_ids.sql
-- Adds stripe_customer_id to profiles and organizations so we can look up
-- the Stripe customer without hitting the Stripe API on every request.
-- Also adds stripe_subscription_id columns for quick lookups in webhooks.
-- =============================================================================

-- profiles — individual learners
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS stripe_customer_id    text UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text UNIQUE;

-- organizations — org billing
ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS stripe_customer_id    text UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text UNIQUE;

-- Indexes for webhook lookups (we receive customer_id and subscription_id
-- from Stripe and need to find the matching row quickly)
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id
  ON public.profiles(stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_stripe_subscription_id
  ON public.profiles(stripe_subscription_id)
  WHERE stripe_subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_stripe_customer_id
  ON public.organizations(stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_stripe_subscription_id
  ON public.organizations(stripe_subscription_id)
  WHERE stripe_subscription_id IS NOT NULL;

-- Also index org_subscriptions on external_sub_id for webhook lookups
CREATE INDEX IF NOT EXISTS idx_org_subscriptions_external_sub_id
  ON public.org_subscriptions(external_sub_id)
  WHERE external_sub_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_subscriptions_external_sub_id
  ON public.subscriptions(external_sub_id)
  WHERE external_sub_id IS NOT NULL;
