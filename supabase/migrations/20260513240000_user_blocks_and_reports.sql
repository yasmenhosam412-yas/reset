-- Block / report users: storage + atomic block (clears friend requests & pending challenges).

create table if not exists public.user_blocks (
  blocker_user_id uuid not null references public.profiles (id) on delete cascade,
  blocked_user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  constraint user_blocks_not_self check (blocker_user_id <> blocked_user_id)
);

create index if not exists user_blocks_blocked_user_id_idx
  on public.user_blocks (blocked_user_id);

comment on table public.user_blocks is
  'blocker_user_id chose to block blocked_user_id; used to hide mutual feed presence.';

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_user_id uuid not null references public.profiles (id) on delete cascade,
  reason text,
  details text,
  context jsonb,
  created_at timestamptz not null default now(),
  constraint user_reports_not_self check (reporter_id <> reported_user_id)
);

create index if not exists user_reports_created_at_idx
  on public.user_reports (created_at desc);

comment on table public.user_reports is
  'User-submitted safety reports; staff review out of band.';

alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;

drop policy if exists "user_blocks_select_own" on public.user_blocks;
create policy "user_blocks_select_own"
  on public.user_blocks for select
  to authenticated
  using (auth.uid() = blocker_user_id or auth.uid() = blocked_user_id);

drop policy if exists "user_blocks_insert_own" on public.user_blocks;
create policy "user_blocks_insert_own"
  on public.user_blocks for insert
  to authenticated
  with check (auth.uid() = blocker_user_id);

drop policy if exists "user_blocks_delete_own" on public.user_blocks;
create policy "user_blocks_delete_own"
  on public.user_blocks for delete
  to authenticated
  using (auth.uid() = blocker_user_id);

drop policy if exists "user_reports_insert_own" on public.user_reports;
create policy "user_reports_insert_own"
  on public.user_reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

-- Atomic block: row + remove friendship / pending requests + pending challenges between the pair.
create or replace function public.block_user (p_blocked uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  if p_blocked is null or p_blocked = me then
    raise exception 'invalid blocked user';
  end if;

  insert into public.user_blocks (blocker_user_id, blocked_user_id)
  values (me, p_blocked)
  on conflict (blocker_user_id, blocked_user_id) do nothing;

  delete from public.friend_requests fr
  where (fr.from_user_id = me and fr.to_user_id = p_blocked)
     or (fr.from_user_id = p_blocked and fr.to_user_id = me);

  delete from public.game_challenges gc
  where (gc.from_user_id = me and gc.to_user_id = p_blocked)
     or (gc.from_user_id = p_blocked and gc.to_user_id = me);
end;
$$;

revoke all on function public.block_user (uuid) from public;
grant execute on function public.block_user (uuid) to authenticated;
