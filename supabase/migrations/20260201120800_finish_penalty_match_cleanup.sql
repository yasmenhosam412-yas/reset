-- When a penalty shootout ends: mark challenge completed, clear ready flags,
-- and remove session + round pick rows (both players may call; idempotent).

alter table public.game_challenges
  drop constraint if exists game_challenges_status_check;

alter table public.game_challenges
  add constraint game_challenges_status_check
  check (
    status in (
      'pending',
      'accepted',
      'declined',
      'expired',
      'cancelled',
      'completed'
    )
  );

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
    to_ready = false
  where id = p_challenge_id;
end;
$$;

revoke all on function public.finish_penalty_match_cleanup(uuid) from public;
grant execute on function public.finish_penalty_match_cleanup(uuid) to authenticated;
