-- Clean up orphan friend-request inbox rows and keep them clean on deletes.

-- One-time cleanup: remove friend_request notifications whose request row no longer exists.
delete from public.user_notifications un
where un.kind = 'friend_request'
  and (
    coalesce(un.data->>'request_id', '') = ''
    or not exists (
      select 1
      from public.friend_requests fr
      where fr.id::text = un.data->>'request_id'
    )
  );

-- Ongoing cleanup: when a friend_request row is deleted (e.g. account deletion),
-- remove its inbox notification for the recipient.
create or replace function public.trg_friend_request_delete_clear_inbox ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.user_notifications
  where kind = 'friend_request'
    and user_id = old.to_user_id
    and data->>'request_id' = old.id::text;
  return old;
end;
$$;

drop trigger if exists friend_requests_delete_clear_inbox on public.friend_requests;

create trigger friend_requests_delete_clear_inbox
  after delete on public.friend_requests
  for each row
  execute procedure public.trg_friend_request_delete_clear_inbox ();

revoke all on function public.trg_friend_request_delete_clear_inbox () from public;
