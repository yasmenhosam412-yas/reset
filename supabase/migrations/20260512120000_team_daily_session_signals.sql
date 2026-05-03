-- Reliable "Match-day rhythm" (session_move) for penalty: record both players on cleanup.
-- Survives missing completed_at / trigger issues and deleted session rows.

alter table public.game_challenges
  add column if not exists completed_at timestamptz null;

create table if not exists public.team_daily_session_signals (
  user_id uuid not null references public.profiles (id) on delete cascade,
  signal_day date not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, signal_day)
);

create index if not exists team_daily_session_signals_day_idx
  on public.team_daily_session_signals (signal_day desc);

alter table public.team_daily_session_signals enable row level security;

drop policy if exists "team_daily_session_signals_select_own"
  on public.team_daily_session_signals;
create policy "team_daily_session_signals_select_own"
  on public.team_daily_session_signals for select
  to authenticated
  using (auth.uid() = user_id);

revoke insert, update, delete on public.team_daily_session_signals from authenticated;

-- ---------------------------------------------------------------------------
-- Penalty cleanup: stamp completed_at + record both players for session_move
-- ---------------------------------------------------------------------------
create or replace function public.finish_penalty_match_cleanup(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  d date := (timezone('utc', now()))::date;
  from_id uuid;
  to_id uuid;
begin
  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  select gc.from_user_id, gc.to_user_id
    into from_id, to_id
  from public.game_challenges gc
  where gc.id = p_challenge_id;

  delete from public.penalty_round_picks
  where challenge_id = p_challenge_id;

  delete from public.penalty_shootout_sessions
  where challenge_id = p_challenge_id;

  update public.game_challenges
  set
    status = 'completed',
    from_ready = false,
    to_ready = false,
    completed_at = coalesce(
      completed_at,
      timezone('utc', now())
    )
  where id = p_challenge_id;

  insert into public.team_daily_session_signals (user_id, signal_day)
  values (from_id, d)
  on conflict (user_id, signal_day) do nothing;

  insert into public.team_daily_session_signals (user_id, signal_day)
  values (to_id, d)
  on conflict (user_id, signal_day) do nothing;
end;
$$;

revoke all on function public.finish_penalty_match_cleanup(uuid) from public;
grant execute on function public.finish_penalty_match_cleanup(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- claim_team_daily_challenge: session_move counts penalty signal rows
-- ---------------------------------------------------------------------------
create or replace function public.claim_team_daily_challenge(p_challenge_key text)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  tz_day date := (timezone('utc', now()))::date;
  pts int := 0;
  eligible boolean := false;
  new_bal int;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if exists (
    select 1
    from public.team_challenge_daily_claims c
    where c.user_id = uid
      and c.challenge_key = p_challenge_key
      and c.claim_day = tz_day
  ) then
    return jsonb_build_object('ok', false, 'error', 'already_claimed');
  end if;

  case p_challenge_key
    when 'pitch_report' then
      pts := 12;
      eligible := true;
    when 'crowd_energy' then
      pts := 20;
      eligible := exists (
        select 1
        from public.posts p
        where p.user_id = uid
          and ((p.created_at at time zone 'utc')::date) = tz_day
      );
    when 'session_move' then
      pts := 22;
      eligible := exists (
        select 1
        from public.penalty_shootout_sessions ps
        join public.game_challenges gc on gc.id = ps.challenge_id
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and ((ps.updated_at at time zone 'utc')::date) = tz_day
      )
      or exists (
        select 1
        from public.rim_shot_sessions rs
        join public.game_challenges gc on gc.id = rs.challenge_id
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and ((rs.updated_at at time zone 'utc')::date) = tz_day
      )
      or exists (
        select 1
        from public.fantasy_duel_sessions fd
        join public.game_challenges gc on gc.id = fd.challenge_id
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and ((fd.updated_at at time zone 'utc')::date) = tz_day
      )
      or exists (
        select 1
        from public.one_v_one_sessions o
        join public.game_challenges gc on gc.id = o.challenge_id
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and ((o.updated_at at time zone 'utc')::date) = tz_day
      )
      or exists (
        select 1
        from public.game_challenges gc
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and gc.status = 'completed'
          and gc.completed_at is not null
          and ((gc.completed_at at time zone 'utc')::date) = tz_day
      )
      or exists (
        select 1
        from public.team_daily_session_signals s
        where s.user_id = uid
          and s.signal_day = tz_day
      );
    else
      return jsonb_build_object('ok', false, 'error', 'unknown_challenge');
  end case;

  if not eligible then
    return jsonb_build_object('ok', false, 'error', 'requirements_not_met');
  end if;

  insert into public.team_challenge_daily_claims (
    user_id,
    challenge_key,
    claim_day,
    points_awarded
  )
  values (uid, p_challenge_key, tz_day, pts);

  update public.profiles
  set team_skill_points = team_skill_points + pts
  where id = uid
  returning team_skill_points into new_bal;

  return jsonb_build_object(
    'ok', true,
    'points_awarded', pts,
    'balance', new_bal
  );
end;
$$;
