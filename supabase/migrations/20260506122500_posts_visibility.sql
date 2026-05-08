-- Post audience:
-- - general: visible to everyone in home feed
-- - friends: visible to author + accepted friends only
alter table public.posts
  add column if not exists post_visibility text not null default 'general';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'posts_post_visibility_check'
  ) then
    alter table public.posts
      add constraint posts_post_visibility_check
      check (post_visibility in ('general', 'friends'));
  end if;
end $$;

comment on column public.posts.post_visibility is
  'Post audience: general (all users) or friends (author + accepted friends).';
