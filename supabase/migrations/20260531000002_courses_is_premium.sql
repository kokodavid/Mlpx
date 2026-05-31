-- Add is_premium flag to courses
-- Premium courses are only accessible to users with premium or sponsored plan_type.
-- NOTE: this is distinct from `locked`, which gates courses by level progression.

ALTER TABLE public.courses
  ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.courses.is_premium IS
  'When true the course requires a premium or sponsored subscription to access.';
