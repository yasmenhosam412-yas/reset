alter table public.posts
add column if not exists ad_link text;

alter table public.posts
drop constraint if exists posts_ad_link_for_ads_check;

-- Backfill legacy rows created before ad_link existed.
-- If an ads row has no valid http/https link, downgrade it to a normal post.
update public.posts
set post_type = 'post'
where post_type = 'ads'
  and (
    ad_link is null
    or btrim(ad_link) = ''
    or ad_link !~* '^https?://'
  );

alter table public.posts
add constraint posts_ad_link_for_ads_check
check (
  post_type <> 'ads'
  or (
    ad_link is not null
    and btrim(ad_link) <> ''
    and ad_link ~* '^https?://'
  )
);

