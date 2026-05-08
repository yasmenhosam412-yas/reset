-- Enforce unique usernames (case-insensitive, trimmed) on public.profiles.
-- This migration is defensive: it normalizes existing rows to avoid index-creation
-- failures from blanks/duplicates.

-- 1) Trim current usernames.
update public.profiles
set username = trim(coalesce(username, ''));

-- 2) Fill blanks with a deterministic fallback.
update public.profiles
set username = 'user_' || substr(replace(id::text, '-', ''), 1, 8)
where coalesce(trim(username), '') = '';

-- 3) Resolve case-insensitive duplicates by suffixing later rows.
with ranked as (
  select
    id,
    username,
    row_number() over (
      partition by lower(trim(username))
      order by id
    ) as rn
  from public.profiles
)
update public.profiles p
set username = p.username || '_' || r.rn::text
from ranked r
where p.id = r.id
  and r.rn > 1;

-- 4) Minimum quality guard.
alter table public.profiles
  drop constraint if exists profiles_username_not_empty_chk;

alter table public.profiles
  add constraint profiles_username_not_empty_chk
  check (length(trim(username)) >= 3);

-- 5) Unique by normalized value.
create unique index if not exists profiles_username_unique_norm_idx
  on public.profiles ((lower(trim(username))));
