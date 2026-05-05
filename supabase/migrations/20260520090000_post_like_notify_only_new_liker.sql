-- Only enqueue like notifications when the acting user was not already in OLD.likes.
-- Prevents duplicate inbox + push rows when likes JSON grows for reasons other than
-- a genuine new like from auth.uid() (e.g. reordering, repair, or edge-case updates).

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

  -- Genuine first-time like from this actor for this update (not already in previous array).
  if old_likes @> to_jsonb(liker::text) then
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
