-- Bookmarks: each user can save posts for later (home feed + Saved screen).
create table if not exists public.post_saves (
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create index if not exists post_saves_user_saved_at_idx
  on public.post_saves (user_id, saved_at desc);

alter table public.post_saves enable row level security;

drop policy if exists "post_saves_select_own" on public.post_saves;
create policy "post_saves_select_own"
  on public.post_saves for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "post_saves_insert_own" on public.post_saves;
create policy "post_saves_insert_own"
  on public.post_saves for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "post_saves_update_own" on public.post_saves;
create policy "post_saves_update_own"
  on public.post_saves for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "post_saves_delete_own" on public.post_saves;
create policy "post_saves_delete_own"
  on public.post_saves for delete
  to authenticated
  using (auth.uid() = user_id);
