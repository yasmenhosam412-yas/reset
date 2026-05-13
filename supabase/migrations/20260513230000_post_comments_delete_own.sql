-- Allow authenticated users to delete only their own post_comments rows.

drop policy if exists "post_comments_delete_own" on public.post_comments;

create policy "post_comments_delete_own"
  on public.post_comments for delete
  to authenticated
  using (auth.uid() = user_id);
