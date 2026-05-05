-- Fix infinite recursion in RLS policy checks between:
-- - party_game_rooms.select policy (looked into members)
-- - party_game_room_members policies (looked into rooms)
--
-- Strategy:
-- 1) Keep room access broad for authenticated users (same as other social tables).
-- 2) Keep strict write rules (host-only for rooms; host/self for members).
-- 3) Keep member reads to involved users (self or host).

drop policy if exists "party_game_rooms_select_involved" on public.party_game_rooms;
drop policy if exists "party_game_rooms_select_authenticated" on public.party_game_rooms;
create policy "party_game_rooms_select_authenticated"
  on public.party_game_rooms for select
  to authenticated
  using (true);

drop policy if exists "party_game_room_members_select_involved" on public.party_game_room_members;
create policy "party_game_room_members_select_involved"
  on public.party_game_room_members for select
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1
      from public.party_game_rooms r
      where r.id = room_id
        and r.host_user_id = auth.uid()
    )
  );
