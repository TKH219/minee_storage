insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

drop policy if exists product_images_read on storage.objects;
create policy product_images_read on storage.objects
  for select to public
  using (bucket_id = 'product-images');

drop policy if exists product_images_insert_own on storage.objects;
create policy product_images_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and (storage.foldername(name))[2] = auth.uid()::text);

drop policy if exists product_images_update_own on storage.objects;
create policy product_images_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'product-images' and (storage.foldername(name))[2] = auth.uid()::text);

drop policy if exists product_images_delete_own on storage.objects;
create policy product_images_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and (storage.foldername(name))[2] = auth.uid()::text);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001400', 'product_images_bucket')
on conflict (version) do nothing;
