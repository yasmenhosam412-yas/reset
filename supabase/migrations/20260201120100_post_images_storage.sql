-- Public bucket for post images (URLs stored in public.posts.post_image).
insert into storage.buckets (id, name, public)
values ('post_images', 'post_images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "post_images_select_public" on storage.objects;
create policy "post_images_select_public"
  on storage.objects for select
  to public
  using (bucket_id = 'post_images');

drop policy if exists "post_images_insert_authenticated" on storage.objects;
create policy "post_images_insert_authenticated"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'post_images');

drop policy if exists "post_images_update_authenticated" on storage.objects;
create policy "post_images_update_authenticated"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'post_images')
  with check (bucket_id = 'post_images');

drop policy if exists "post_images_delete_authenticated" on storage.objects;
create policy "post_images_delete_authenticated"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'post_images');
