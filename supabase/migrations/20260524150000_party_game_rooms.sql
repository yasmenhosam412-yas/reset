-- Party rooms for local party games (2-5 players) with invite flow.

create table if not exists public.party_game_rooms (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references public.profiles (id) on delete cascade,
  game_id integer not null,
  max_players integer not null default 2
    check (max_players between 2 and 5),
  status text not null default 'open'
    check (status in ('open', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.party_game_room_members (
  room_id uuid not null references public.party_game_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  invited_by uuid references public.profiles (id) on delete set null,
  status text not null default 'invited'
    check (status in ('invited', 'joined', 'declined', 'left')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create index if not exists party_game_room_members_user_status_idx
  on public.party_game_room_members (user_id, status);

alter table public.party_game_rooms enable row level security;
alter table public.party_game_room_members enable row level security;

drop policy if exists "party_game_rooms_select_involved" on public.party_game_rooms;
create policy "party_game_rooms_select_involved"
  on public.party_game_rooms for select
  to authenticated
  using (
    auth.uid() = host_user_id
    or exists (
      select 1
      from public.party_game_room_members m
      where m.room_id = id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "party_game_rooms_insert_host" on public.party_game_rooms;
create policy "party_game_rooms_insert_host"
  on public.party_game_rooms for insert
  to authenticated
  with check (auth.uid() = host_user_id);

drop policy if exists "party_game_rooms_update_host" on public.party_game_rooms;
create policy "party_game_rooms_update_host"
  on public.party_game_rooms for update
  to authenticated
  using (auth.uid() = host_user_id)
  with check (auth.uid() = host_user_id);

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

drop policy if exists "party_game_room_members_insert_host_or_self" on public.party_game_room_members;
create policy "party_game_room_members_insert_host_or_self"
  on public.party_game_room_members for insert
  to authenticated
  with check (
    auth.uid() = user_id
    or exists (
      select 1
      from public.party_game_rooms r
      where r.id = room_id
        and r.host_user_id = auth.uid()
    )
  );

drop policy if exists "party_game_room_members_update_involved" on public.party_game_room_members;
create policy "party_game_room_members_update_involved"
  on public.party_game_room_members for update
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1
      from public.party_game_rooms r
      where r.id = room_id
        and r.host_user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    or exists (
      select 1
      from public.party_game_rooms r
      where r.id = room_id
        and r.host_user_id = auth.uid()
    )
  );
