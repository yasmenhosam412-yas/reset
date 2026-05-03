-- Leaving an online match from the app: remove all session rows for the challenge
-- and mark the challenge cancelled (idempotent for missing session tables).

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
