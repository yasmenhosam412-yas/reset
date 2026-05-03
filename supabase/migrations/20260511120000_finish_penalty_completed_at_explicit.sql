-- Penalty cleanup already sets status = 'completed'; stamp completed_at in the same UPDATE
-- so "session_move" eligibility does not depend only on the BEFORE trigger (and stays correct
-- if completed_at was never set by older trigger definitions).

create or replace function public.finish_penalty_match_cleanup(p_challenge_id uuid)
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
end;
$$;
