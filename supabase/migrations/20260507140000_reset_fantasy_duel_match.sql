-- Rematch: clear trios, match wins, and completion so the same challenge can duel again.

create or replace function public.reset_fantasy_duel_match(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_seed integer;
begin
  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  v_seed := greatest(
    1,
    abs(hashtext(p_challenge_id::text || '#rematch#' || floor(extract(epoch from now()) * 1000)::text))
  );

  update public.fantasy_duel_sessions
  set
    from_trio = null,
    to_trio = null,
    round_number = 1,
    from_match_wins = 0,
    to_match_wins = 0,
    match_complete = false,
    deck_seed = v_seed,
    updated_at = now()
  where challenge_id = p_challenge_id;
end;
$$;

revoke all on function public.reset_fantasy_duel_match(uuid) from public;
grant execute on function public.reset_fantasy_duel_match(uuid) to authenticated;
