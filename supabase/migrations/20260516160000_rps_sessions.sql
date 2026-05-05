-- Rock–paper–scissors online (game ID 2): both lock a throw, then server resolves the round.

create table if not exists public.rps_sessions (
  challenge_id uuid primary key
    references public.game_challenges (id) on delete cascade,
  score_from integer not null default 0
    check (score_from >= 0 and score_from <= 10),
  score_to integer not null default 0
    check (score_to >= 0 and score_to <= 10),
  from_pick text null
    check (from_pick is null or from_pick in ('rock', 'paper', 'scissors')),
  to_pick text null
    check (to_pick is null or to_pick in ('rock', 'paper', 'scissors')),
  round_seq integer not null default 0
    check (round_seq >= 0),
  status text not null default 'playing'
    check (status in ('playing', 'done')),
  updated_at timestamptz not null default now()
);

create index if not exists rps_sessions_updated_idx
  on public.rps_sessions (updated_at desc);

alter table public.rps_sessions enable row level security;

drop policy if exists "rps_sessions_select" on public.rps_sessions;
create policy "rps_sessions_select"
  on public.rps_sessions for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rps_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "rps_sessions_insert" on public.rps_sessions;
create policy "rps_sessions_insert"
  on public.rps_sessions for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rps_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "rps_sessions_update" on public.rps_sessions;
create policy "rps_sessions_update"
  on public.rps_sessions for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rps_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rps_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

create or replace function public.ensure_rps_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.rps_sessions (challenge_id)
  values (p_challenge_id)
  on conflict (challenge_id) do nothing;
end;
$$;

revoke all on function public.ensure_rps_session(uuid) from public;
grant execute on function public.ensure_rps_session(uuid) to authenticated;

create or replace function public.reset_rps_match(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
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

  insert into public.rps_sessions (challenge_id)
  values (p_challenge_id)
  on conflict (challenge_id) do nothing;

  update public.rps_sessions
  set
    score_from = 0,
    score_to = 0,
    from_pick = null,
    to_pick = null,
    round_seq = 0,
    status = 'playing',
    updated_at = now()
  where challenge_id = p_challenge_id;
end;
$$;

revoke all on function public.reset_rps_match(uuid) from public;
grant execute on function public.reset_rps_match(uuid) to authenticated;

create or replace function public.submit_rps_pick(
  p_challenge_id uuid,
  p_as_from boolean,
  p_pick text
)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  r public.rps_sessions%rowtype;
  sf int;
  st int;
  rs int;
  stt text;
  rw int;
  sess jsonb;
begin
  if p_pick not in ('rock', 'paper', 'scissors') then
    return jsonb_build_object('ok', false, 'error', 'invalid_pick');
  end if;

  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = uid or gc.to_user_id = uid)
  ) then
    return jsonb_build_object('ok', false, 'error', 'not_participant');
  end if;

  select * into strict r from public.rps_sessions where challenge_id = p_challenge_id for update;

  if r.status = 'done' then
    return jsonb_build_object('ok', false, 'error', 'match_over');
  end if;

  if p_as_from then
    if r.from_pick is not null then
      return jsonb_build_object('ok', false, 'error', 'already_submitted');
    end if;
    update public.rps_sessions
    set from_pick = p_pick, updated_at = now()
    where challenge_id = p_challenge_id;
  else
    if r.to_pick is not null then
      return jsonb_build_object('ok', false, 'error', 'already_submitted');
    end if;
    update public.rps_sessions
    set to_pick = p_pick, updated_at = now()
    where challenge_id = p_challenge_id;
  end if;

  select * into strict r from public.rps_sessions where challenge_id = p_challenge_id;

  if r.from_pick is null or r.to_pick is null then
    select to_jsonb(s) into sess from public.rps_sessions s where s.challenge_id = p_challenge_id;
    return jsonb_build_object(
      'ok', true,
      'resolved_round', false,
      'round_winner', null,
      'session', sess
    );
  end if;

  if r.from_pick = r.to_pick then
    rw := -1;
  elsif (r.from_pick = 'rock' and r.to_pick = 'scissors')
     or (r.from_pick = 'paper' and r.to_pick = 'rock')
     or (r.from_pick = 'scissors' and r.to_pick = 'paper') then
    rw := 0;
  else
    rw := 1;
  end if;

  sf := r.score_from;
  st := r.score_to;
  rs := r.round_seq;

  if rw = 0 then
    sf := sf + 1;
  elsif rw = 1 then
    st := st + 1;
  end if;

  rs := rs + 1;
  stt := 'playing';
  if sf >= 5 or st >= 5 then
    stt := 'done';
  end if;

  update public.rps_sessions
  set
    score_from = sf,
    score_to = st,
    from_pick = null,
    to_pick = null,
    round_seq = rs,
    status = stt,
    updated_at = now()
  where challenge_id = p_challenge_id;

  select to_jsonb(s) into sess from public.rps_sessions s where s.challenge_id = p_challenge_id;
  return jsonb_build_object(
    'ok', true,
    'resolved_round', true,
    'round_winner', rw,
    'session', sess
  );
end;
$$;

revoke all on function public.submit_rps_pick(uuid, boolean, text) from public;
grant execute on function public.submit_rps_pick(uuid, boolean, text) to authenticated;

alter table public.rps_sessions replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'rps_sessions'
  ) then
    alter publication supabase_realtime add table public.rps_sessions;
  end if;
end $$;

create or replace function public.abandon_online_game_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
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

  delete from public.penalty_round_picks
  where challenge_id = p_challenge_id;

  delete from public.penalty_shootout_sessions
  where challenge_id = p_challenge_id;

  delete from public.rim_shot_sessions
  where challenge_id = p_challenge_id;

  delete from public.rps_sessions
  where challenge_id = p_challenge_id;

  delete from public.fantasy_duel_sessions
  where challenge_id = p_challenge_id;

  delete from public.one_v_one_sessions
  where challenge_id = p_challenge_id;

  update public.game_challenges
  set
    status = 'cancelled',
    from_ready = false,
    to_ready = false
  where id = p_challenge_id;
end;
$$;

revoke all on function public.abandon_online_game_session(uuid) from public;
grant execute on function public.abandon_online_game_session(uuid) to authenticated;

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
        from public.rps_sessions rp
        join public.game_challenges gc on gc.id = rp.challenge_id
        where (gc.from_user_id = uid or gc.to_user_id = uid)
          and ((rp.updated_at at time zone 'utc')::date) = tz_day
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

revoke all on function public.claim_team_daily_challenge(text) from public;
grant execute on function public.claim_team_daily_challenge(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Skill points: game ID 2 now uses `rps_sessions` (fallback to legacy rim row).
-- ---------------------------------------------------------------------------
create or replace function public.award_online_challenge_winner_skill_points(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  gid int;
  from_u uuid;
  to_u uuid;
  winner uuid;
  fg int;
  tg int;
  mc boolean;
begin
  select gc.game_id, gc.from_user_id, gc.to_user_id
  into gid, from_u, to_u
  from public.game_challenges gc
  where gc.id = p_challenge_id;

  if not found then
    return;
  end if;

  winner := null;

  if gid = 1 then
    select ps.from_goals, ps.to_goals into fg, tg
    from public.penalty_shootout_sessions ps
    where ps.challenge_id = p_challenge_id;
    if found then
      if fg > tg then
        winner := from_u;
      elsif tg > fg then
        winner := to_u;
      end if;
    end if;
  elsif gid = 2 then
    select rp.score_from, rp.score_to into fg, tg
    from public.rps_sessions rp
    where rp.challenge_id = p_challenge_id
      and rp.status = 'done';
    if not found then
      select rs.score_from, rs.score_to into fg, tg
      from public.rim_shot_sessions rs
      where rs.challenge_id = p_challenge_id
        and rs.status = 'done';
    end if;
    if found then
      if fg > tg then
        winner := from_u;
      elsif tg > fg then
        winner := to_u;
      end if;
    end if;
  elsif gid = 3 then
    select s.from_match_wins, s.to_match_wins, s.match_complete
    into fg, tg, mc
    from public.fantasy_duel_sessions s
    where s.challenge_id = p_challenge_id;
    if found and mc is true then
      if fg > tg then
        winner := from_u;
      elsif tg > fg then
        winner := to_u;
      end if;
    end if;
  end if;

  if winner is null then
    return;
  end if;

  with ins as (
    insert into public.online_challenge_skill_rewards (
      challenge_id,
      winner_user_id,
      points
    )
    values (p_challenge_id, winner, 10)
    on conflict (challenge_id) do nothing
    returning winner_user_id
  )
  update public.profiles p
  set team_skill_points = team_skill_points + 10
  from ins
  where p.id = ins.winner_user_id;
end;
$$;

revoke all on function public.award_online_challenge_winner_skill_points(uuid) from public;

create or replace function public.trg_rps_award_skill_points()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if new.status = 'done' and (old.status is distinct from new.status) then
    perform public.award_online_challenge_winner_skill_points(new.challenge_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_rps_award_skill_points on public.rps_sessions;
create trigger trg_rps_award_skill_points
  after update of status on public.rps_sessions
  for each row
  execute procedure public.trg_rps_award_skill_points();
