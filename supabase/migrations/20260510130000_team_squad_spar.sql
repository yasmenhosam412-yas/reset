-- Once per UTC day per friend pair: compare saved squads (Power race formula). Winner earns team_skill_points; tie splits a smaller reward.

create table if not exists public.team_squad_spar_daily (
  participant_lo uuid not null,
  participant_hi uuid not null,
  claim_day date not null,
  initiator uuid not null,
  score_lo integer not null,
  score_hi integer not null,
  winner uuid,
  primary key (participant_lo, participant_hi, claim_day),
  constraint team_squad_spar_order check (participant_lo < participant_hi)
);

alter table public.team_squad_spar_daily enable row level security;

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

  select team_skill_points into new_bal
  from public.profiles
  where id = uid;

  return jsonb_build_object(
    'ok', true,
    'outcome', my_outcome,
    'my_score', sc_me,
    'opponent_score', sc_opp,
    'points_awarded', pts_awarded,
    'balance', new_bal
  );
end;
$$;

revoke all on function public.claim_team_squad_spar(uuid) from public;
grant execute on function public.claim_team_squad_spar(uuid) to authenticated;
