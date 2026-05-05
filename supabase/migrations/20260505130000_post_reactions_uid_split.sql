-- Support post reactions stored as jsonb text elements: plain `user_id` (like) or `user_id|reaction_key`.
-- Notifications must treat `user_id` as the actor when comparing OLD.likes.

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
  old_likes jsonb;
  new_likes jsonb;
  already_liked_before boolean;
  already_notified boolean;
begin
  if tg_op <> 'UPDATE' then
    return NEW;
  end if;
  if NEW.likes is not distinct from OLD.likes then
    return NEW;
  end if;

  old_likes := coalesce(OLD.likes, '[]'::jsonb);
  new_likes := coalesce(NEW.likes, '[]'::jsonb);

  if jsonb_array_length(new_likes) <= jsonb_array_length(old_likes) then
    return NEW;
  end if;

  liker := auth.uid();
  if liker is null or liker = NEW.user_id then
    return NEW;
  end if;

  select exists (
    select 1
    from jsonb_array_elements_text(old_likes) as t(uid_text)
    where lower(trim(split_part(trim(t.uid_text), '|', 1)))
          = lower(trim(liker::text))
  ) into already_liked_before;

  if already_liked_before then
    return NEW;
  end if;

  select exists (
    select 1
    from public.user_notifications un
    where un.user_id = NEW.user_id
      and un.kind = 'post_like'
      and un.data->>'post_id' = NEW.id::text
      and lower(trim(coalesce(un.data->>'actor_id', '')))
        = lower(trim(liker::text))
  ) into already_notified;

  if already_notified then
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
