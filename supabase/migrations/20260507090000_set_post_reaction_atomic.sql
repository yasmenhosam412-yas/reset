-- Atomic reaction setter to avoid lost updates when multiple users react concurrently.
-- Stores reactions as jsonb text entries:
--   - "user_id"            => like
--   - "user_id|reaction"   => non-like reaction

create or replace function public.set_post_reaction(
  p_post_id uuid,
  p_reaction text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_reaction text;
  v_existing jsonb;
  v_next jsonb;
  v_encoded text;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  v_reaction := lower(trim(coalesce(p_reaction, '')));
  if v_reaction = '' then
    v_reaction := null;
  end if;

  if v_reaction is not null
     and v_reaction not in ('like', 'love', 'laugh', 'wow', 'sad', 'care') then
    raise exception 'Unknown reaction: %', p_reaction;
  end if;

  select coalesce(p.likes, '[]'::jsonb)
    into v_existing
  from public.posts p
  where p.id = p_post_id
  for update;

  if not found then
    raise exception 'Post not found: %', p_post_id;
  end if;

  -- Remove any previous reaction from this user.
  select coalesce(jsonb_agg(to_jsonb(t.e)), '[]'::jsonb)
    into v_next
  from (
    select e
    from jsonb_array_elements_text(v_existing) as t(e)
    where lower(trim(split_part(trim(t.e), '|', 1))) <> lower(trim(v_uid::text))
  ) as t;

  -- Add next reaction (or none if clearing).
  if v_reaction is not null then
    if v_reaction = 'like' then
      v_encoded := v_uid::text;
    else
      v_encoded := v_uid::text || '|' || v_reaction;
    end if;
    v_next := v_next || jsonb_build_array(v_encoded);
  end if;

  update public.posts
  set likes = v_next
  where id = p_post_id;
end;
$$;

revoke all on function public.set_post_reaction(uuid, text) from public;
grant execute on function public.set_post_reaction(uuid, text) to authenticated;

