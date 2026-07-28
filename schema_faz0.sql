-- NightCompare — FAZ 0: Altyapı Hazırlığı (Round 3)
-- schema.sql ve schema_reviews.sql zaten çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- cities
create table cities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table cities enable row level security;
create policy "cities_select_all" on cities for select using (true);
insert into cities (name, slug, is_active) values ('Bursa', 'bursa', true);

-- venues.city_id (backfill + not null)
alter table venues add column city_id uuid references cities(id);
update venues set city_id = (select id from cities where slug = 'bursa') where city_id is null;
alter table venues alter column city_id set not null;

-- venue_categories (kategori lookup — hardcoded JS dizisinin DB karşılığı)
create table venue_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
alter table venue_categories enable row level security;
create policy "venue_categories_select_all" on venue_categories for select using (true);
insert into venue_categories (name, icon, sort_order) values
  ('Bira','🍺',1), ('Viski','🥃',2), ('Vodka','🍸',3), ('Şarap','🍷',4), ('Kokteyl','🍹',5);

-- venue_views (görüntülenme sayacı — anonim dahil herkes)
create table venue_views (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid references profiles(id),
  created_at timestamptz not null default now()
);
alter table venue_views enable row level security;
create policy "venue_views_select_all" on venue_views for select using (true);
create policy "venue_views_insert_all" on venue_views for insert with check (true);

-- venue_visits (ziyaret kaydı — şema burada hazırlanıyor, yazma mantığı Faz 2.2 "Gece Rotası → Rotayı Başlat" ile bağlanacak)
create table venue_visits (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid references profiles(id),
  created_at timestamptz not null default now()
);
alter table venue_visits enable row level security;
create policy "venue_visits_select_all" on venue_visits for select using (true);
create policy "venue_visits_insert_all" on venue_visits for insert with check (true);
