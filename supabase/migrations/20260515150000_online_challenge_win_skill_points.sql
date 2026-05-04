-- Winner of an online game challenge (penalty / rim / fantasy) earns +10 team_skill_points once per challenge.
-- Losers are unchanged. Idempotent via online_challenge_skill_rewards.

create table if not exists public.online_challenge_skill_rewards (
  challenge_id uuid primary key references public.game_challenges (id) on delete cascade,
  winner_user_id uuid not null references public.profiles (id) on delete cascade,
  points int not null default 10 check (points > 0),
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.online_challenge_skill_rewards enable row level security;

-- ---------------------------------------------------------------------------
-- Internal: compute winner from live session rows and grant points (no client execute).
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
    select rs.score_from, rs.score_to into fg, tg
    from public.rim_shot_sessions rs
    where rs.challenge_id = p_challenge_id
      and rs.status = 'done';
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

-- ---------------------------------------------------------------------------
-- Penalty: award while session goals still exist, then existing cleanup.
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

  perform public.award_online_challenge_winner_skill_points(p_challenge_id);

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
-- Fantasy: after a successful round advance, maybe award match winner.
-- ---------------------------------------------------------------------------
create or replace function public.fantasy_duel_finish_round_and_advance(
  p_challenge_id uuid,
  p_completed_round int,
  p_from_points int,
  p_to_points int
) returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_win_threshold int := 5;
  v_updated int;
begin
  if p_from_points < 0 or p_from_points > 1 or p_to_points < 0 or p_to_points > 1 then
    raise exception 'invalid round points';
  end if;

  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  update public.fantasy_duel_sessions s
  set
    from_match_wins = s.from_match_wins + p_from_points,
    to_match_wins = s.to_match_wins + p_to_points,
    match_complete = (
      (s.from_match_wins + p_from_points) >= v_win_threshold
      or (s.to_match_wins + p_to_points) >= v_win_threshold
    ),
    from_trio = null,
    to_trio = null,
    round_number = case
      when (
        (s.from_match_wins + p_from_points) >= v_win_threshold
        or (s.to_match_wins + p_to_points) >= v_win_threshold
      )
      then s.round_number
      else s.round_number + 1
    end,
    deck_seed = case
      when (
        (s.from_match_wins + p_from_points) >= v_win_threshold
        or (s.to_match_wins + p_to_points) >= v_win_threshold
      )
      then s.deck_seed
      else greatest(
        1,
        abs(hashtext(p_challenge_id::text || '#' || (s.round_number + 1)::text))
      )
    end,
    updated_at = now()
  where s.challenge_id = p_challenge_id
    and s.match_complete = false
    and s.round_number = p_completed_round
    and s.from_trio is not null
    and s.to_trio is not null;

  get diagnostics v_updated = row_count;

  if v_updated > 0 then
    perform public.award_online_challenge_winner_skill_points(p_challenge_id);
  end if;
end;
$$;

revoke all on function public.fantasy_duel_finish_round_and_advance(uuid, int, int, int) from public;
grant execute on function public.fantasy_duel_finish_round_and_advance(uuid, int, int, int) to authenticated;

-- ---------------------------------------------------------------------------
-- Rim shot: when session flips to done, award from final scores.
-- ---------------------------------------------------------------------------
create or replace function public.trg_rim_shot_award_skill_points()
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

drop trigger if exists trg_rim_shot_award_skill_points on public.rim_shot_sessions;
create trigger trg_rim_shot_award_skill_points
  after update of status on public.rim_shot_sessions
  for each row
  execute procedure public.trg_rim_shot_award_skill_points();
