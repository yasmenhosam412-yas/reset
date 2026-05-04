-- Squad spar: winners can gain +1 on a random stat (max 99); losers can lose −1 on a random stat (min 40).
-- Response includes updated team_squad plus stat_bonus / stat_penalty payloads for the client.

create or replace function public.claim_team_squad_spar(p_opponent uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  opp uuid := p_opponent;
  lo uuid;
  hi uuid;
  tz_day date := (timezone('utc', now()))::date;
  squad_me jsonb;
  squad_opp jsonb;
  pl_me jsonb;
  pl_opp jsonb;
  sc_me int;
  sc_opp int;
  sc_lo int;
  sc_hi int;
  win uuid;
  win_pts int := 20;
  tie_pts int := 8;
  new_bal int;
  my_outcome text;
  pts_awarded int := 0;
  stat_keys text[] := array['attack','defense','speed','stamina'];
  slot_i int;
  sk text;
  curv int;
  newv int;
  attempt int;
  bonus jsonb := null;
  penalty jsonb := null;
  squad_out jsonb;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if opp is null or opp = uid then
    return jsonb_build_object('ok', false, 'error', 'cannot_spar_self');
  end if;

  if uid < opp then
    lo := uid;
    hi := opp;
  else
    lo := opp;
    hi := uid;
  end if;

  if exists (
    select 1
    from public.team_squad_spar_daily d
    where d.participant_lo = lo
      and d.participant_hi = hi
      and d.claim_day = tz_day
  ) then
    return jsonb_build_object('ok', false, 'error', 'already_sparred');
  end if;

  if not exists (
    select 1
    from public.friend_requests fr
    where fr.status = 'accepted'
      and (
        (fr.from_user_id = uid and fr.to_user_id = opp)
        or (fr.from_user_id = opp and fr.to_user_id = uid)
      )
  ) then
    return jsonb_build_object('ok', false, 'error', 'not_friends');
  end if;

  select team_squad into squad_me from public.profiles where id = uid;
  select team_squad into squad_opp from public.profiles where id = opp;

  if squad_me is null or squad_me->'players' is null then
    return jsonb_build_object('ok', false, 'error', 'no_squad_saved');
  end if;

  if squad_opp is null or squad_opp->'players' is null then
    return jsonb_build_object('ok', false, 'error', 'opponent_no_squad');
  end if;

  pl_me := squad_me->'players';
  pl_opp := squad_opp->'players';
  if jsonb_array_length(pl_me) <> 6 or jsonb_array_length(pl_opp) <> 6 then
    return jsonb_build_object('ok', false, 'error', 'bad_squad');
  end if;

  sc_me := public._lineup_race_score(pl_me, 'power');
  sc_opp := public._lineup_race_score(pl_opp, 'power');

  if lo = uid then
    sc_lo := sc_me;
    sc_hi := sc_opp;
  else
    sc_lo := sc_opp;
    sc_hi := sc_me;
  end if;

  if sc_lo > sc_hi then
    win := lo;
  elsif sc_hi > sc_lo then
    win := hi;
  else
    win := null;
  end if;

  if win is not null then
    update public.profiles
    set team_skill_points = team_skill_points + win_pts
    where id = win;
  else
    update public.profiles
    set team_skill_points = team_skill_points + tie_pts
    where id in (lo, hi);
  end if;

  insert into public.team_squad_spar_daily (
    participant_lo,
    participant_hi,
    claim_day,
    initiator,
    score_lo,
    score_hi,
    winner
  )
  values (lo, hi, tz_day, uid, sc_lo, sc_hi, win);

  if win is not null then
    if win = uid then
      my_outcome := 'win';
      pts_awarded := win_pts;
    else
      my_outcome := 'lose';
      pts_awarded := 0;
    end if;
  else
    my_outcome := 'tie';
    pts_awarded := tie_pts;
  end if;

  -- Refresh squad JSON, then apply high-stakes stat swing for initiator only.
  select team_squad into squad_me from public.profiles where id = uid;
  pl_me := squad_me->'players';

  if my_outcome = 'win' then
    FOR attempt IN 1..36 LOOP
      slot_i := floor(random() * 6)::int;
      sk := stat_keys[1 + floor(random() * 4)::int];
      curv := coalesce((pl_me->(slot_i::text)->>sk)::int, 70);
      curv := greatest(least(curv, 99), 40);
      if curv < 99 then
        newv := curv + 1;
        pl_me := jsonb_set(pl_me, array[slot_i::text, sk], to_jsonb(newv), true);
        bonus := jsonb_build_object(
          'slot', slot_i,
          'stat', sk,
          'before', curv,
          'after', newv
        );
        exit;
      end if;
    end loop;
  elsif my_outcome = 'lose' then
    FOR attempt IN 1..36 LOOP
      slot_i := floor(random() * 6)::int;
      sk := stat_keys[1 + floor(random() * 4)::int];
      curv := coalesce((pl_me->(slot_i::text)->>sk)::int, 70);
      curv := greatest(least(curv, 99), 40);
      if curv > 40 then
        newv := curv - 1;
        pl_me := jsonb_set(pl_me, array[slot_i::text, sk], to_jsonb(newv), true);
        penalty := jsonb_build_object(
          'slot', slot_i,
          'stat', sk,
          'before', curv,
          'after', newv
        );
        exit;
      end if;
    end loop;
  end if;

  squad_me := jsonb_set(squad_me, '{players}', pl_me, true);
  update public.profiles
  set team_squad = squad_me
  where id = uid;

  select team_skill_points, team_squad
  into new_bal, squad_out
  from public.profiles
  where id = uid;

  return jsonb_build_object(
    'ok', true,
    'outcome', my_outcome,
    'my_score', sc_me,
    'opponent_score', sc_opp,
    'points_awarded', pts_awarded,
    'balance', new_bal,
    'team_squad', squad_out,
    'stat_bonus', bonus,
    'stat_penalty', penalty
  );
end;
$$;

revoke all on function public.claim_team_squad_spar(uuid) from public;
grant execute on function public.claim_team_squad_spar(uuid) to authenticated;
