-- Allow authors to delete their own feed posts (comments cascade via FK).
drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id);
