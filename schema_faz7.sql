-- NightCompare — Supabase Storage (Fotoğraf Yükleme)
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

insert into storage.buckets (id, name, public) values ('venue-photos', 'venue-photos', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true) on conflict (id) do nothing;

create policy "venue_photos_public_read" on storage.objects for select using (bucket_id = 'venue-photos');
create policy "venue_photos_auth_insert" on storage.objects for insert with check (bucket_id = 'venue-photos' and auth.uid() is not null);

create policy "avatars_public_read" on storage.objects for select using (bucket_id = 'avatars');
create policy "avatars_auth_write_own" on storage.objects for insert with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_auth_update_own" on storage.objects for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

alter table profiles add column avatar_url text;
