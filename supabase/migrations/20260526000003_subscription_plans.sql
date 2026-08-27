-- =============================================================================
-- Migration: subscription_plans & plan_features
--
-- Defines the purchasable packages shown on the learner app paywall.
-- Admins manage these from the dashboard; the learner app fetches active plans.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- subscription_plans  — one row per purchasable package
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text          NOT NULL,                        -- e.g. "Premium Monthly"
  description      text,                                          -- short tagline
  plan_type        plan_type     NOT NULL DEFAULT 'premium',      -- maps to existing enum
  billing_cycle    billing_cycle NOT NULL DEFAULT 'monthly',
  price_usd        numeric(10,2) NOT NULL DEFAULT 0.00,
  is_active        boolean       NOT NULL DEFAULT true,           -- false = hidden from paywall
  is_highlighted   boolean       NOT NULL DEFAULT false,          -- show "Most popular" badge
  sort_order       int           NOT NULL DEFAULT 0,              -- display order on paywall
  stripe_price_id  text,                                          -- optional: Stripe price ID
  rc_product_id    text,                                          -- optional: RevenueCat product ID
  created_at       timestamptz   NOT NULL DEFAULT now(),
  updated_at       timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT subscription_plans_price_non_negative CHECK (price_usd >= 0)
);

CREATE INDEX idx_subscription_plans_active ON public.subscription_plans(is_active, sort_order);

-- -----------------------------------------------------------------------------
-- plan_features  — bullet points shown on the paywall for each plan
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.plan_features (
  id          uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id     uuid    NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  label       text    NOT NULL,       -- e.g. "Unlimited lessons"
  is_included boolean NOT NULL DEFAULT true,  -- false = shown as ✗ (not included)
  sort_order  int     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_features_plan_id ON public.plan_features(plan_id, sort_order);

-- -----------------------------------------------------------------------------
-- updated_at trigger
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_subscription_plans_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.set_subscription_plans_updated_at();

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_features       ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY "Admins full access on subscription_plans"
  ON public.subscription_plans FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "Admins full access on plan_features"
  ON public.plan_features FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

-- Any authenticated user can read active plans (needed by the paywall)
CREATE POLICY "Authenticated users can read active plans"
  ON public.subscription_plans FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Authenticated users can read plan features"
  ON public.plan_features FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.subscription_plans p
      WHERE p.id = plan_features.plan_id
        AND p.is_active = true
    )
  );

-- -----------------------------------------------------------------------------
-- Seed data  — default plans (admins can edit or delete these)
-- -----------------------------------------------------------------------------
INSERT INTO public.subscription_plans
  (name, description, plan_type, billing_cycle, price_usd, is_active, is_highlighted, sort_order)
VALUES
  ('Free',             'Get started with beginner content',         'free',    'monthly', 0.00,  true, false, 0),
  ('Premium Monthly',  'Full access to all lessons and downloads',  'premium', 'monthly', 4.99,  true, true,  1),
  ('Premium Annual',   'Full access — save 17% with annual billing','premium', 'annual',  49.99, true, false, 2)
ON CONFLICT DO NOTHING;

-- Seed features for Free plan
WITH free_plan AS (SELECT id FROM public.subscription_plans WHERE name = 'Free' LIMIT 1)
INSERT INTO public.plan_features (plan_id, label, is_included, sort_order)
SELECT id, feat.label, feat.included, feat.ord
FROM free_plan,
(VALUES
  ('Beginner courses',           true,  0),
  ('Progress tracking',          true,  1),
  ('All lessons & levels',       false, 2),
  ('Offline downloads',          false, 3),
  ('Assessments',                false, 4)
) AS feat(label, included, ord)
ON CONFLICT DO NOTHING;

-- Seed features for Premium Monthly plan
WITH plan AS (SELECT id FROM public.subscription_plans WHERE name = 'Premium Monthly' LIMIT 1)
INSERT INTO public.plan_features (plan_id, label, is_included, sort_order)
SELECT id, feat.label, feat.included, feat.ord
FROM plan,
(VALUES
  ('All lessons & levels',  true, 0),
  ('Offline downloads',     true, 1),
  ('Assessments',           true, 2),
  ('Progress tracking',     true, 3),
  ('Priority support',      true, 4)
) AS feat(label, included, ord)
ON CONFLICT DO NOTHING;

-- Seed features for Premium Annual plan (same as monthly)
WITH plan AS (SELECT id FROM public.subscription_plans WHERE name = 'Premium Annual' LIMIT 1)
INSERT INTO public.plan_features (plan_id, label, is_included, sort_order)
SELECT id, feat.label, feat.included, feat.ord
FROM plan,
(VALUES
  ('All lessons & levels',  true, 0),
  ('Offline downloads',     true, 1),
  ('Assessments',           true, 2),
  ('Progress tracking',     true, 3),
  ('Priority support',      true, 4)
) AS feat(label, included, ord)
ON CONFLICT DO NOTHING;
