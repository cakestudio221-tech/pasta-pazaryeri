-- NightCompare Redesign — Round 3: Mekan Detayı
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Çalışma saatleri, müzik türü, olanaklar
alter table venues add column working_hours text;
alter table venues add column music_genre text;
alter table venues add column amenities text[] not null default '{}';

-- Fotoğraf galerisi (birden fazla fotoğraf, mevcut venue-photos bucket'ı kullanılır)
create table venue_photos (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  url text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
alter table venue_photos enable row level security;
create policy "venue_photos_select_all" on venue_photos for select using (true);
create policy "venue_photos_insert_owner" on venue_photos for insert with check (
  is_admin() or exists (select 1 from venues where id = venue_id and created_by = auth.uid())
);
create policy "venue_photos_delete_owner" on venue_photos for delete using (
  is_admin() or exists (select 1 from venues where id = venue_id and created_by = auth.uid())
);
