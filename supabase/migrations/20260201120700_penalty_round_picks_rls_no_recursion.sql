-- Fix: SELECT policy on penalty_round_picks counted rows from the same table,
-- which re-evaluated RLS and caused "infinite recursion detected in policy".
-- Use a SECURITY DEFINER helper with row_security disabled for the count only.

create or replace function public.penalty_round_picks_count_for_round(
  p_challenge_id uuid,
  p_round_index integer
) returns integer
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select count(*)::int
  from public.penalty_round_picks
  where challenge_id = p_challenge_id
    and round_index = p_round_index;
$$;

revoke all on function public.penalty_round_picks_count_for_round(uuid, integer)
  from public;
grant execute on function public.penalty_round_picks_count_for_round(uuid, integer)
  to authenticated;

drop policy if exists "penalty_picks_select" on public.penalty_round_picks;

create policy "penalty_picks_select"
  on public.penalty_round_picks for select
  to authenticated
  using (
    auth.uid() = user_id
    or (
      exists (
        select 1
        from public.game_challenges gc
        where gc.id = penalty_round_picks.challenge_id
          and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
      )
      and public.penalty_round_picks_count_for_round(
        penalty_round_picks.challenge_id,
        penalty_round_picks.round_index
      ) >= 2
    )
  );
