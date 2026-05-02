-- Penalty shootout: shared session scores + per-round picks hidden until both submit.

-- ---------------------------------------------------------------------------
-- penalty_shootout_sessions
-- ---------------------------------------------------------------------------
create table if not exists public.penalty_shootout_sessions (
  challenge_id uuid primary key
    references public.game_challenges (id) on delete cascade,
  round_index integer not null default 0
    check (round_index >= 0 and round_index <= 64),
  from_goals integer not null default 0
    check (from_goals >= 0),
  to_goals integer not null default 0
    check (to_goals >= 0),
  updated_at timestamptz not null default now()
);

create index if not exists penalty_shootout_sessions_updated_idx
  on public.penalty_shootout_sessions (updated_at desc);

alter table public.penalty_shootout_sessions enable row level security;

drop policy if exists "penalty_sessions_select" on public.penalty_shootout_sessions;
create policy "penalty_sessions_select"
  on public.penalty_shootout_sessions for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_shootout_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "penalty_sessions_insert" on public.penalty_shootout_sessions;
create policy "penalty_sessions_insert"
  on public.penalty_shootout_sessions for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_shootout_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "penalty_sessions_update" on public.penalty_shootout_sessions;
create policy "penalty_sessions_update"
  on public.penalty_shootout_sessions for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_shootout_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = penalty_shootout_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- penalty_round_picks (two rows per round; RLS hides opponent until both exist)
-- ---------------------------------------------------------------------------
create table if not exists public.penalty_round_picks (
  challenge_id uuid not null
    references public.game_challenges (id) on delete cascade,
  round_index integer not null
    check (round_index >= 0),
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  pick_kind text not null
    check (pick_kind in ('shot', 'dive')),
  direction smallint not null
    check (direction in (-1, 0, 1)),
  power double precision
    check (
      power is null
      or (power >= 0::double precision and power <= 1::double precision)
    ),
  created_at timestamptz not null default now(),
  constraint penalty_round_picks_pk primary key (challenge_id, round_index, user_id),
  constraint penalty_round_picks_shot_power check (
    (pick_kind = 'dive' and power is null)
    or (
      pick_kind = 'shot'
      and power is not null
      and power >= 0::double precision
      and power <= 1::double precision
    )
  )
);

create index if not exists penalty_round_picks_challenge_round_idx
  on public.penalty_round_picks (challenge_id, round_index);

alter table public.penalty_round_picks enable row level security;

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
      and (
        select count(*)::int
        from public.penalty_round_picks pr
        where pr.challenge_id = penalty_round_picks.challenge_id
          and pr.round_index = penalty_round_picks.round_index
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

-- ---------------------------------------------------------------------------
-- RPC: idempotent round advance (only one client wins the UPDATE)
-- ---------------------------------------------------------------------------
create or replace function public.advance_penalty_round(
  p_challenge_id uuid,
  p_expected_round integer,
  p_from_delta integer,
  p_to_delta integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  if p_from_delta not in (0, 1) or p_to_delta not in (0, 1) then
    raise exception 'invalid deltas';
  end if;

  update public.penalty_shootout_sessions
  set
    from_goals = from_goals + p_from_delta,
    to_goals = to_goals + p_to_delta,
    round_index = round_index + 1,
    updated_at = now()
  where challenge_id = p_challenge_id
    and round_index = p_expected_round;

  get diagnostics n = row_count;
  return n > 0;
end;
$$;

revoke all on function public.advance_penalty_round(uuid, integer, integer, integer)
  from public;
grant execute on function public.advance_penalty_round(uuid, integer, integer, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: create session row once
-- ---------------------------------------------------------------------------
create or replace function public.ensure_penalty_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  insert into public.penalty_shootout_sessions (challenge_id)
  values (p_challenge_id)
  on conflict (challenge_id) do nothing;
end;
$$;

revoke all on function public.ensure_penalty_session(uuid) from public;
grant execute on function public.ensure_penalty_session(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
alter table public.penalty_shootout_sessions replica identity full;
alter table public.penalty_round_picks replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'penalty_shootout_sessions'
  ) then
    alter publication supabase_realtime add table public.penalty_shootout_sessions;
  end if;
end $$;

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
