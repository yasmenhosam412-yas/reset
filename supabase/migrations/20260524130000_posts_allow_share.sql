-- Author can disable reposts for a post (default: others may repost).
alter table public.posts
  add column if not exists allow_share boolean not null default true;

comment on column public.posts.allow_share is
  'When false, other users should not get Repost on this post.';
