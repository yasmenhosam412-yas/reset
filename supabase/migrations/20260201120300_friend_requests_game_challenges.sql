-- Friend requests and game challenges (used by HomeDatasourceImpl)

-- ---------------------------------------------------------------------------
-- friend_requests
-- ---------------------------------------------------------------------------
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles (id) on delete cascade,
  to_user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  constraint friend_requests_not_self check (from_user_id <> to_user_id),
  constraint friend_requests_unique_pair unique (from_user_id, to_user_id)
);

create index if not exists friend_requests_to_user_id_idx
  on public.friend_requests (to_user_id);

create index if not exists friend_requests_from_user_id_idx
  on public.friend_requests (from_user_id);

-- ---------------------------------------------------------------------------
-- game_challenges
-- ---------------------------------------------------------------------------
create table if not exists public.game_challenges (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles (id) on delete cascade,
  to_user_id uuid not null references public.profiles (id) on delete cascade,
  game_id integer not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
  created_at timestamptz not null default now(),
  constraint game_challenges_not_self check (from_user_id <> to_user_id)
);

create unique index if not exists game_challenges_pending_unique
  on public.game_challenges (from_user_id, to_user_id, game_id)
  where status = 'pending';

create index if not exists game_challenges_to_user_id_idx
  on public.game_challenges (to_user_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.friend_requests enable row level security;
alter table public.game_challenges enable row level security;

drop policy if exists "friend_requests_select_involved" on public.friend_requests;
create policy "friend_requests_select_involved"
  on public.friend_requests for select
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "friend_requests_insert_as_sender" on public.friend_requests;
create policy "friend_requests_insert_as_sender"
  on public.friend_requests for insert
  to authenticated
  with check (auth.uid() = from_user_id);

drop policy if exists "friend_requests_update_involved" on public.friend_requests;
create policy "friend_requests_update_involved"
  on public.friend_requests for update
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "game_challenges_select_involved" on public.game_challenges;
create policy "game_challenges_select_involved"
  on public.game_challenges for select
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "game_challenges_insert_as_sender" on public.game_challenges;
create policy "game_challenges_insert_as_sender"
  on public.game_challenges for insert
  to authenticated
  with check (auth.uid() = from_user_id);

drop policy if exists "game_challenges_update_involved" on public.game_challenges;
create policy "game_challenges_update_involved"
  on public.game_challenges for update
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);
