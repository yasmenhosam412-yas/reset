-- Restrict post updates to the author (was open to any authenticated user).
drop policy if exists "posts_update_authenticated" on public.posts;
drop policy if exists "posts_update_own" on public.posts;

create policy "posts_update_own"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
