-- Shared score board per room for party games.

create table if not exists public.party_game_room_scores (
  room_id uuid not null references public.party_game_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  score integer not null default 0,
  meta jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create index if not exists party_game_room_scores_room_score_idx
  on public.party_game_room_scores (room_id, score desc, updated_at desc);

alter table public.party_game_room_scores enable row level security;

drop policy if exists "party_game_room_scores_select_involved" on public.party_game_room_scores;
create policy "party_game_room_scores_select_involved"
  on public.party_game_room_scores for select
  to authenticated
  using (
    exists (
      select 1
      from public.party_game_room_members m
      where m.room_id = room_id
        and m.user_id = auth.uid()
        and m.status = 'joined'
    )
  );

drop policy if exists "party_game_room_scores_upsert_joined_self" on public.party_game_room_scores;
create policy "party_game_room_scores_upsert_joined_self"
  on public.party_game_room_scores for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.party_game_room_members m
      where m.room_id = room_id
        and m.user_id = auth.uid()
        and m.status = 'joined'
    )
  );

drop policy if exists "party_game_room_scores_update_joined_self" on public.party_game_room_scores;
create policy "party_game_room_scores_update_joined_self"
  on public.party_game_room_scores for update
  to authenticated
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.party_game_room_members m
      where m.room_id = room_id
        and m.user_id = auth.uid()
        and m.status = 'joined'
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.party_game_room_members m
      where m.room_id = room_id
        and m.user_id = auth.uid()
        and m.status = 'joined'
    )
  );
