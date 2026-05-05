-- When a host creates a party room, invited members get in-app alerts + push (queue).

alter table public.user_notifications
  drop constraint if exists user_notifications_kind_chk;

alter table public.user_notifications
  add constraint user_notifications_kind_chk check (
    kind in (
      'post_like',
      'post_comment',
      'friend_request',
      'party_room_invite'
    )
  );

create or replace function public.trg_party_room_invite_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  inviter uuid;
  actor_name text;
  v_game_id int;
  v_title text;
  v_body text;
begin
  if NEW.status is distinct from 'invited' then
    return NEW;
  end if;

  inviter := NEW.invited_by;
  if inviter is null then
    select r.host_user_id into inviter
    from public.party_game_rooms r
    where r.id = NEW.room_id;
  end if;

  if inviter is null or inviter = NEW.user_id then
    return NEW;
  end if;

  select coalesce(r.game_id, 0) into v_game_id
  from public.party_game_rooms r
  where r.id = NEW.room_id;

  select nullif(trim(username), '') into actor_name
  from public.profiles
  where id = inviter;

  v_title := 'Party room invite';
  v_body := coalesce(actor_name, 'Someone') || ' invited you to a party game.';

  perform public.log_user_notification(
    NEW.user_id,
    'party_room_invite',
    v_title,
    v_body,
    jsonb_build_object(
      'type', 'party_room_invite',
      'room_id', NEW.room_id::text,
      'game_id', v_game_id::text,
      'host_user_id', inviter::text
    )
  );

  perform public.queue_push_notify(
    NEW.user_id,
    v_title,
    v_body,
    jsonb_build_object(
      'type', 'party_room_invite',
      'room_id', NEW.room_id::text,
      'game_id', v_game_id::text
    )
  );

  return NEW;
end;
$$;

drop trigger if exists party_room_member_invite_notify on public.party_game_room_members;

create trigger party_room_member_invite_notify
  after insert on public.party_game_room_members
  for each row
  execute procedure public.trg_party_room_invite_notify ();

revoke all on function public.trg_party_room_invite_notify () from public;
