-- Skill points, saved squad JSON, daily challenge claims, and RPCs for Team tab progression.

alter table public.profiles
  add column if not exists team_skill_points integer not null default 0
  check (team_skill_points >= 0);

alter table public.profiles
  add column if not exists team_squad jsonb null;

-- ---------------------------------------------------------------------------
-- team_challenge_daily_claims (inserts only via SECURITY DEFINER RPC)
-- ---------------------------------------------------------------------------
create table if not exists public.team_challenge_daily_claims (
  user_id uuid not null references public.profiles (id) on delete cascade,
  challenge_key text not null,
  claim_day date not null,
  points_awarded integer not null check (points_awarded > 0),
  claimed_at timestamptz not null default now(),
  primary key (user_id, challenge_key, claim_day)
);

create index if not exists team_challenge_claims_user_day_idx
  on public.team_challenge_daily_claims (user_id, claim_day desc);

alter table public.team_challenge_daily_claims enable row level security;

drop policy if exists "team_challenge_claims_select_own" on public.team_challenge_daily_claims;
create policy "team_challenge_claims_select_own"
  on public.team_challenge_daily_claims for select
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- claim_team_daily_challenge(p_challenge_key text)
-- Keys: pitch_report | crowd_energy | session_move
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
-- train_team_player(p_slot int, p_stat text)  — costs 15 points, +1 stat (max 99)
-- ---------------------------------------------------------------------------
create or replace function public.train_team_player(p_slot int, p_stat text)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  cost int := 15;
  bal int;
  squad jsonb;
  players jsonb;
  v int;
  new_players jsonb;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_slot < 0 or p_slot > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_slot');
  end if;

  if p_stat not in ('attack', 'defense', 'speed', 'stamina') then
    return jsonb_build_object('ok', false, 'error', 'bad_stat');
  end if;

  select team_skill_points, team_squad
  into bal, squad
  from public.profiles
  where id = uid
  for update;

  if squad is null or squad->'players' is null then
    return jsonb_build_object('ok', false, 'error', 'no_squad_saved');
  end if;

  players := squad->'players';
  if jsonb_array_length(players) <> 6 then
    return jsonb_build_object('ok', false, 'error', 'bad_squad');
  end if;

  if bal < cost then
    return jsonb_build_object('ok', false, 'error', 'not_enough_points');
  end if;

  v := (players->p_slot->>p_stat)::int;
  if v is null or v >= 99 then
    return jsonb_build_object('ok', false, 'error', 'stat_maxed');
  end if;

  new_players := (
    select jsonb_agg(
      q.elem order by q.ord
    )
    from (
      select
        ord,
        case
          when (ord - 1) = p_slot then
            jsonb_set(
              elem,
              array[p_stat],
              to_jsonb(least((elem->>p_stat)::int + 1, 99))
            )
          else elem
        end as elem
      from jsonb_array_elements(players) with ordinality as t(elem, ord)
    ) q
  );

  if new_players is null then
    return jsonb_build_object('ok', false, 'error', 'bad_squad');
  end if;

  squad := jsonb_set(squad, '{players}', new_players);

  update public.profiles
  set
    team_squad = squad,
    team_skill_points = team_skill_points - cost
  where id = uid
  returning team_skill_points into bal;

  return jsonb_build_object(
    'ok', true,
    'balance', bal,
    'team_squad', squad
  );
end;
$$;

revoke all on function public.train_team_player(integer, text) from public;
grant execute on function public.train_team_player(integer, text) to authenticated;
