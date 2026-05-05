-- First player to 5 round wins ends the bout (server must match app).

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
