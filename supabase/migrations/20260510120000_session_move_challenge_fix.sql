-- "Match-day rhythm" / session_move failed after matches ended because session rows are deleted.
-- Fix: stamp completed_at on game_challenges, count one_v_one_sessions, and treat completed-today as eligible.

alter table public.game_challenges
  add column if not exists completed_at timestamptz null;

create or replace function public.trg_game_challenges_set_completed_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'completed' then
    if tg_op = 'INSERT' then
      new.completed_at := coalesce(new.completed_at, timezone('utc', now()));
    elsif old.status is distinct from 'completed' then
      new.completed_at := coalesce(new.completed_at, timezone('utc', now()));
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_game_challenges_set_completed_at on public.game_challenges;
create trigger trg_game_challenges_set_completed_at
  before insert or update on public.game_challenges
  for each row
  execute function public.trg_game_challenges_set_completed_at();

-- ---------------------------------------------------------------------------
-- Re-define claim_team_daily_challenge (session_move branch expanded)
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
