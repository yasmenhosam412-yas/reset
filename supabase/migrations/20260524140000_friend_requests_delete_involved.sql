-- Let either party remove an accepted friendship row (unfriend).
drop policy if exists "friend_requests_delete_involved" on public.friend_requests;

create policy "friend_requests_delete_involved"
  on public.friend_requests for delete
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);
