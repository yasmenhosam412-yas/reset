-- Ensure all clients see the same room readiness state.
-- Previous policy only let host/self read member rows, so joined counts
-- differed between users in the same room.

drop policy if exists "party_game_room_members_select_involved" on public.party_game_room_members;
drop policy if exists "party_game_room_members_select_authenticated" on public.party_game_room_members;

create policy "party_game_room_members_select_authenticated"
  on public.party_game_room_members for select
  to authenticated
  using (true);
