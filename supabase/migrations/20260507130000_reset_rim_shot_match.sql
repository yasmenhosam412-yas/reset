-- Rematch from "Play again": clear rim shot scores and reopen play for the same challenge.

create or replace function public.reset_rim_shot_match(p_challenge_id uuid)
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

  update public.rim_shot_sessions
  set
    score_from = 0,
    score_to = 0,
    whose_turn = 'from',
    round_seq = 0,
    last_power = null,
    last_aim = null,
    last_made = null,
    status = 'playing',
    updated_at = now()
  where challenge_id = p_challenge_id;
end;
$$;

revoke all on function public.reset_rim_shot_match(uuid) from public;
grant execute on function public.reset_rim_shot_match(uuid) to authenticated;
