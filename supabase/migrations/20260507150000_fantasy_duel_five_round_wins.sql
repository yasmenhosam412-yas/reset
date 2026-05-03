-- Match length: first to 5 round wins (keep in sync with FantasyDuelGame.kRoundWinsNeeded).

create or replace function public.fantasy_duel_finish_round_and_advance(
  p_challenge_id uuid,
  p_completed_round int,
  p_from_points int,
  p_to_points int
) returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_win_threshold int := 5;
begin
  if p_from_points < 0 or p_from_points > 1 or p_to_points < 0 or p_to_points > 1 then
    raise exception 'invalid round points';
  end if;

  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  update public.fantasy_duel_sessions s
  set
    from_match_wins = s.from_match_wins + p_from_points,
    to_match_wins = s.to_match_wins + p_to_points,
    match_complete = (
      (s.from_match_wins + p_from_points) >= v_win_threshold
      or (s.to_match_wins + p_to_points) >= v_win_threshold
    ),
    from_trio = null,
    to_trio = null,
    round_number = case
      when (
        (s.from_match_wins + p_from_points) >= v_win_threshold
        or (s.to_match_wins + p_to_points) >= v_win_threshold
      )
      then s.round_number
      else s.round_number + 1
    end,
    deck_seed = case
      when (
        (s.from_match_wins + p_from_points) >= v_win_threshold
        or (s.to_match_wins + p_to_points) >= v_win_threshold
      )
      then s.deck_seed
      else greatest(
        1,
        abs(hashtext(p_challenge_id::text || '#' || (s.round_number + 1)::text))
      )
    end,
    updated_at = now()
  where s.challenge_id = p_challenge_id
    and s.match_complete = false
    and s.round_number = p_completed_round
    and s.from_trio is not null
    and s.to_trio is not null;
end;
$$;

revoke all on function public.fantasy_duel_finish_round_and_advance(uuid, int, int, int) from public;
grant execute on function public.fantasy_duel_finish_round_and_advance(uuid, int, int, int) to authenticated;
