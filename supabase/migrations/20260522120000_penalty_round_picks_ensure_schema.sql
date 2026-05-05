-- Idempotent repair: ensure public.penalty_round_picks exists and matches the
-- Flutter penalty client (five aim lanes -2..2, null power for shots).
-- Fixes DBs that never ran the original shootout migration, or ALTER-only
-- migrations that failed because the table was missing.

create table if not exists public.penalty_round_picks (
  challenge_id uuid not null
    references public.game_challenges (id) on delete cascade,
  round_index integer not null
    check (round_index >= 0),
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  pick_kind text not null
    check (pick_kind in ('shot', 'dive')),
  direction smallint not null,
  power double precision,
  created_at timestamptz not null default now(),
  constraint penalty_round_picks_pk primary key (challenge_id, round_index, user_id)
);

create index if not exists penalty_round_picks_challenge_round_idx
  on public.penalty_round_picks (challenge_id, round_index);

-- Drop any legacy direction checks (e.g. classic three lanes only).
do $$
declare
  r record;
begin
  for r in
    select c.conname as name
    from pg_constraint c
    join pg_class t on c.conrelid = t.oid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'penalty_round_picks'
      and c.contype = 'c'
      and pg_get_constraintdef(c.oid) like '%direction%'
  loop
    execute format(
      'alter table public.penalty_round_picks drop constraint %I',
      r.name
    );
  end loop;
end $$;

alter table public.penalty_round_picks
  drop constraint if exists penalty_round_picks_direction_lane_check;

alter table public.penalty_round_picks
  add constraint penalty_round_picks_direction_lane_check
  check (direction >= -2 and direction <= 2);

alter table public.penalty_round_picks
  drop constraint if exists penalty_round_picks_shot_power;

alter table public.penalty_round_picks
  add constraint penalty_round_picks_shot_power check (
    (pick_kind = 'dive' and power is null)
    or (
      pick_kind = 'shot'
      and (
        power is null
        or (
          power >= 0::double precision
          and power <= 1::double precision
        )
      )
    )
  );

alter table public.penalty_round_picks enable row level security;

create or replace function public.penalty_round_picks_count_for_round(
  p_challenge_id uuid,
  p_round_index integer
) returns integer
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select count(*)::int
  from public.penalty_round_picks
  where challenge_id = p_challenge_id
    and round_index = p_round_index;
$$;

revoke all on function public.penalty_round_picks_count_for_round(uuid, integer)
  from public;
grant execute on function public.penalty_round_picks_count_for_round(uuid, integer)
  to authenticated;

drop policy if exists "penalty_picks_select" on public.penalty_round_picks;
create policy "penalty_picks_select"
  on public.penalty_round_picks for select
  to authenticated
  using (
    auth.uid() = user_id
    or (
      exists (
        select 1
        from public.game_challenges gc
        where gc.id = penalty_round_picks.challenge_id
          and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
      )
      and public.penalty_round_picks_count_for_round(
        penalty_round_picks.challenge_id,
        penalty_round_picks.round_index
      ) >= 2
    )
  );

drop policy if exists "penalty_picks_insert" on public.penalty_round_picks;
create policy "penalty_picks_insert"
  on public.penalty_round_picks for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_round_picks.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "penalty_picks_update" on public.penalty_round_picks;
create policy "penalty_picks_update"
  on public.penalty_round_picks for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_round_picks.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "penalty_picks_delete" on public.penalty_round_picks;
create policy "penalty_picks_delete"
  on public.penalty_round_picks for delete
  to authenticated
  using (auth.uid() = user_id);

alter table public.penalty_round_picks replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'penalty_round_picks'
  ) then
    alter publication supabase_realtime add table public.penalty_round_picks;
  end if;
end $$;
