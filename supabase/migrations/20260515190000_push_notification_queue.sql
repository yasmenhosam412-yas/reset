-- FCM delivery: rows are inserted here; send via Supabase Edge Function + Database Webhook
-- (Dashboard → Database → Webhooks → INSERT on public.push_notification_queue → your function URL),
-- or poll the queue from a scheduled function.

alter table public.profiles
  add column if not exists fcm_token text;

alter table public.profiles
  add column if not exists push_notifications_enabled boolean not null default true;

comment on column public.profiles.fcm_token is 'Firebase Cloud Messaging device token.';
comment on column public.profiles.push_notifications_enabled is
  'When false, queue_push_notify skips this user (client should sync from Profile toggle).';

create table if not exists public.push_notification_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists push_notification_queue_pending_idx
  on public.push_notification_queue (created_at desc)
  where processed_at is null;

alter table public.push_notification_queue enable row level security;

-- No policies: only service role / triggers (security definer) write; clients cannot read the queue.

create or replace function public.queue_push_notify (
  p_user_id uuid,
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
  insert into public.push_notification_queue (user_id, title, body, data)
  select
    p_user_id,
    p_title,
    p_body,
    coalesce(p_data, '{}'::jsonb)
  from public.profiles pr
  where pr.id = p_user_id
    and coalesce(pr.push_notifications_enabled, true)
    and pr.fcm_token is not null
    and length(trim(pr.fcm_token)) > 0;
end;
$$;

revoke all on function public.queue_push_notify (uuid, text, text, jsonb) from public;

-- New like on someone else’s post (likes jsonb array grows).
create or replace function public.trg_posts_like_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  liker uuid;
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

drop trigger if exists posts_like_push_notify on public.posts;

create trigger posts_like_push_notify
  after update of likes on public.posts
  for each row
  execute procedure public.trg_posts_like_push_notify ();

revoke all on function public.trg_posts_like_push_notify () from public;

-- New comment (not on own post).
create or replace function public.trg_post_comment_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  author uuid;
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

drop trigger if exists post_comments_push_notify on public.post_comments;

create trigger post_comments_push_notify
  after insert on public.post_comments
  for each row
  execute procedure public.trg_post_comment_push_notify ();

revoke all on function public.trg_post_comment_push_notify () from public;

-- Incoming friend request.
create or replace function public.trg_friend_request_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.status is distinct from 'pending' then
    return NEW;
  end if;
  if NEW.from_user_id = NEW.to_user_id then
    return NEW;
  end if;
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

drop trigger if exists friend_requests_push_notify on public.friend_requests;

create trigger friend_requests_push_notify
  after insert on public.friend_requests
  for each row
  execute procedure public.trg_friend_request_push_notify ();

revoke all on function public.trg_friend_request_push_notify () from public;

-- New online challenge invite (row only exists if recipient accepts invites trigger passed).
create or replace function public.trg_game_challenge_push_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.from_user_id = NEW.to_user_id then
    return NEW;
  end if;
  perform public.queue_push_notify(
    NEW.to_user_id,
    'Match invite',
    'You have a new online game invite.',
    jsonb_build_object(
      'type', 'challenge_invite',
      'challenge_id', NEW.id::text
    )
  );
  return NEW;
end;
$$;

drop trigger if exists game_challenges_push_notify on public.game_challenges;

create trigger game_challenges_push_notify
  after insert on public.game_challenges
  for each row
  execute procedure public.trg_game_challenge_push_notify ();

revoke all on function public.trg_game_challenge_push_notify () from public;

-- ---------------------------------------------------------------------------
-- Delivery: deploy Edge Function `process-push-queue` and set secrets:
--   FIREBASE_SERVICE_ACCOUNT_JSON  (full JSON string of Firebase service account)
--   PUSH_PROCESS_SECRET            (optional: shared secret; send as header
--                                    `x-push-process-secret` on webhook/cron)
-- In Supabase Dashboard → Integrations → Database Webhooks (or Database Hooks):
--   Event: INSERT on public.push_notification_queue
--   HTTP POST to: https://<project-ref>.supabase.co/functions/v1/process-push-queue
--   Headers: x-push-process-secret: <PUSH_PROCESS_SECRET>
-- Fallback: POST with service role Authorization and body {"process_batch":true}
-- to drain pending rows (e.g. cron or manual).
-- ---------------------------------------------------------------------------
