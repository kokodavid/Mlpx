# Weekly Goal Feature

This feature stores a user's weekly lesson goal and supports custom values.

## Supabase Schema

```sql
-- Enable if not already present
create extension if not exists pgcrypto;

create table if not exists public.user_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  goal_type text not null,
  goal_value integer not null check (goal_value > 0),
  timezone text not null,
  week_start smallint not null default 1, -- 1 = Monday
  active_from timestamptz not null default now(),
  active_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists user_goals_active_unique
  on public.user_goals (user_id, goal_type)
  where active_until is null;

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists user_goals_set_updated_at on public.user_goals;
create trigger user_goals_set_updated_at
before update on public.user_goals
for each row execute procedure public.set_updated_at();
```

## Notes
- Use `goal_type = 'lessons_per_week'` for this feature.
- `timezone` should store an IANA timezone string (e.g. `Africa/Nairobi`).
- `week_start = 1` assumes Monday-based weeks.
