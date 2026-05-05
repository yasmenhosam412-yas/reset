-- In-app notification inbox (likes, comments, friend requests).
-- Push queue remains separate; this table is always written so the Alerts tab works
-- without an FCM token. Match invites stay on game_challenges + OnlineBloc only.

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint user_notifications_kind_chk check (
    kind in ('post_like', 'post_comment', 'friend_request')
  )
);

create index if not exists user_notifications_user_created_idx
  on public.user_notifications (user_id, created_at desc);

alter table public.user_notifications enable row level security;

drop policy if exists "user_notifications_select_own" on public.user_notifications;
create policy "user_notifications_select_own"
  on public.user_notifications for select
  to authenticated
  using (auth.uid() = user_id);

grant select on public.user_notifications to authenticated;

create or replace function public.log_user_notification (
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_data jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_notifications (user_id, kind, title, body, data)
  values (
    p_user_id,
    p_kind,
    p_title,
    p_body,
    coalesce(p_data, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.log_user_notification (uuid, text, text, text, jsonb) from public;

-- ---------------------------------------------------------------------------
-- Extend existing push triggers: also persist inbox rows (with actor names).
-- ---------------------------------------------------------------------------

create or replace function public.trg_posts_like_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  liker uuid;
  actor_name text;
  v_body text;
begin
  if tg_op <> 'UPDATE' then
    return NEW;
  end if;
  if NEW.likes is not distinct from OLD.likes then
    return NEW;
  end if;
  if jsonb_array_length(coalesce(NEW.likes, '[]'::jsonb))
     <= jsonb_array_length(coalesce(OLD.likes, '[]'::jsonb)) then
    return NEW;
  end if;
  liker := auth.uid();
  if liker is null or liker = NEW.user_id then
    return NEW;
  end if;

  select nullif(trim(username), '') into actor_name
  from public.profiles where id = liker;
  v_body := coalesce(actor_name, 'Someone') || ' liked your post.';

  perform public.log_user_notification(
    NEW.user_id,
    'post_like',
    'New like',
    v_body,
    jsonb_build_object(
      'type', 'post_like',
      'post_id', NEW.id::text,
      'actor_id', liker::text
    )
  );

  perform public.queue_push_notify(
    NEW.user_id,
    'New like',
    'Someone liked your post.',
    jsonb_build_object(
      'type', 'post_like',
      'post_id', NEW.id::text
    )
  );
  return NEW;
end;
$$;

create or replace function public.trg_post_comment_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  author uuid;
  actor_name text;
  preview text;
  v_body text;
begin
  select p.user_id into author
  from public.posts p
  where p.id = NEW.post_id;
  if author is null then
    return NEW;
  end if;
  if NEW.user_id = author then
    return NEW;
  end if;

  select nullif(trim(username), '') into actor_name
  from public.profiles where id = NEW.user_id;
  preview := substr(replace(coalesce(NEW.comment, ''), E'\n', ' '), 1, 120);
  v_body := coalesce(actor_name, 'Someone') || ' commented: ' || preview;

  perform public.log_user_notification(
    author,
    'post_comment',
    'New comment',
    v_body,
    jsonb_build_object(
      'type', 'post_comment',
      'post_id', NEW.post_id::text,
      'comment_id', NEW.id::text,
      'actor_id', NEW.user_id::text
    )
  );

  perform public.queue_push_notify(
    author,
    'New comment',
    'Someone commented on your post.',
    jsonb_build_object(
      'type', 'post_comment',
      'post_id', NEW.post_id::text,
      'comment_id', NEW.id::text
    )
  );
  return NEW;
end;
$$;

create or replace function public.trg_friend_request_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_name text;
  v_body text;
begin
  if NEW.status is distinct from 'pending' then
    return NEW;
  end if;
  if NEW.from_user_id = NEW.to_user_id then
    return NEW;
  end if;

  select nullif(trim(username), '') into actor_name
  from public.profiles where id = NEW.from_user_id;
  v_body := coalesce(actor_name, 'Someone') || ' wants to add you as a friend.';

  perform public.log_user_notification(
    NEW.to_user_id,
    'friend_request',
    'Friend request',
    v_body,
    jsonb_build_object(
      'type', 'friend_request',
      'request_id', NEW.id::text,
      'actor_id', NEW.from_user_id::text
    )
  );

  perform public.queue_push_notify(
    NEW.to_user_id,
    'Friend request',
    'Someone wants to be friends with you.',
    jsonb_build_object(
      'type', 'friend_request',
      'request_id', NEW.id::text
    )
  );
  return NEW;
end;
$$;

-- Remove inbox friend-request rows once the recipient accepts or declines.
create or replace function public.trg_friend_request_clear_inbox ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.status is distinct from 'pending' then
    delete from public.user_notifications
    where kind = 'friend_request'
      and user_id = NEW.to_user_id
      and data->>'request_id' = NEW.id::text;
  end if;
  return NEW;
end;
$$;

drop trigger if exists friend_requests_clear_inbox on public.friend_requests;

create trigger friend_requests_clear_inbox
  after update of status on public.friend_requests
  for each row
  execute procedure public.trg_friend_request_clear_inbox ();

revoke all on function public.trg_friend_request_clear_inbox () from public;
