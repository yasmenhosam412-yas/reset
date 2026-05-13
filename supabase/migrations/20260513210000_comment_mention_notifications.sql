-- @-mentions in post comments: inbox row + push queue for each matched profile (not self; not duplicate for post author when they already get post_comment).

alter table public.user_notifications
  drop constraint if exists user_notifications_kind_chk;

alter table public.user_notifications
  add constraint user_notifications_kind_chk check (
    kind in (
      'post_like',
      'post_comment',
      'friend_request',
      'party_room_invite',
      'comment_mention'
    )
  );

create or replace function public.trg_post_comment_mentions_notify ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  post_author uuid;
  actor_name text;
  preview text;
  mention_user uuid;
  v_body text;
begin
  select p.user_id into post_author
  from public.posts p
  where p.id = new.post_id;

  if post_author is null then
    return new;
  end if;

  select nullif(trim(username), '') into actor_name
  from public.profiles where id = new.user_id;

  preview := substr(replace(coalesce(new.comment, ''), e'\n', ' '), 1, 120);

  for mention_user in
    select distinct pr.id
    from lateral regexp_matches(
      coalesce(new.comment, ''),
      '@([A-Za-z0-9_]+)',
      'g'
    ) as rm(m)
    inner join public.profiles pr
      on lower(trim(pr.username)) = lower(trim(both from rm.m[1]))
  loop
    -- no self-mention
    if mention_user = new.user_id then
      continue;
    end if;

    -- post author already gets a generic post_comment row when someone else comments
    if mention_user = post_author and new.user_id <> post_author then
      continue;
    end if;

    v_body := coalesce(actor_name, 'Someone')
      || ' mentioned you in a comment: '
      || coalesce(preview, '');

    perform public.log_user_notification(
      mention_user,
      'comment_mention',
      'You were mentioned',
      v_body,
      jsonb_build_object(
        'type', 'comment_mention',
        'post_id', new.post_id::text,
        'comment_id', new.id::text,
        'actor_id', new.user_id::text,
        'author_id', post_author::text
      )
    );

    perform public.queue_push_notify(
      mention_user,
      'You were mentioned',
      coalesce(actor_name, 'Someone') || ' mentioned you in a comment.',
      jsonb_build_object(
        'type', 'comment_mention',
        'post_id', new.post_id::text,
        'comment_id', new.id::text,
        'actor_id', new.user_id::text,
        'author_id', post_author::text
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists post_comments_mentions_notify on public.post_comments;

create trigger post_comments_mentions_notify
  after insert on public.post_comments
  for each row
  execute procedure public.trg_post_comment_mentions_notify ();

revoke all on function public.trg_post_comment_mentions_notify () from public;
