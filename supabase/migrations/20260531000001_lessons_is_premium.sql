-- Add is_premium flag to lessons
-- Premium lessons are only accessible to users with premium or sponsored plan_type.

ALTER TABLE public.lessons
  ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.lessons.is_premium IS
  'When true the lesson requires a premium or sponsored subscription to access.';
