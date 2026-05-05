-- Daily mini-battles: one row per (battle_id, UTC day, user). All authenticated users see the same leaderboards.

create table if not exists public.global_battle_entries (
  battle_id smallint not null check (battle_id between 1 and 5),
  period_key text not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  score integer not null,
  extras jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (battle_id, period_key, user_id)
);

create index if not exists global_battle_entries_period_rank_idx
  on public.global_battle_entries (battle_id, period_key, score desc, created_at asc);

alter table public.global_battle_entries enable row level security;

drop policy if exists "global_battle_entries_select_auth" on public.global_battle_entries;
create policy "global_battle_entries_select_auth"
  on public.global_battle_entries for select
  to authenticated
  using (true);

drop policy if exists "global_battle_entries_insert_own" on public.global_battle_entries;
create policy "global_battle_entries_insert_own"
  on public.global_battle_entries for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "global_battle_entries_update_own" on public.global_battle_entries;
create policy "global_battle_entries_update_own"
  on public.global_battle_entries for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
