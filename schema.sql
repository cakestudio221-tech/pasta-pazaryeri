-- NightCompare — Supabase schema
-- Bu dosyayı Supabase projesinin SQL Editor'ünde çalıştırın.

create extension if not exists pgcrypto;

-- 1. profiles: her auth kullanıcısı için ek profil bilgisi
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Barmender',
  xp int not null default 0,
  created_at timestamptz not null default now()
);

-- 2. venues: mekanlar
create table venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  district text,
  city text,
  img text,
  rating numeric(2,1) default 0,
  reviews int default 0,
  verified boolean default false,
  distance numeric default 0,
  created_at timestamptz not null default now()
);

-- 3. prices: fiyat bildirimleri (her satır bir katkı/report)
create table prices (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  category text not null,       -- 'Bira','Viski','Vodka','Şarap','Kokteyl'
  drink_name text not null,
  price numeric not null,
  reported_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- 4. favorites: kullanıcı-mekan many-to-many
create table favorites (
  user_id uuid not null references profiles(id) on delete cascade,
  venue_id uuid not null references venues(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, venue_id)
);

-- Yeni auth kullanıcısı oluşunca otomatik profiles satırı oluştur
create function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- Row Level Security
alter table profiles enable row level security;
alter table venues enable row level security;
alter table prices enable row level security;
alter table favorites enable row level security;

-- profiles: herkes okuyabilir, sadece kendi satırını güncelleyebilir
create policy "profiles_select_all" on profiles for select using (true);
create policy "profiles_update_own" on profiles for update using (auth.uid() = id);

-- venues: herkes okuyabilir, insert/update yok (seed data SQL ile girilir)
create policy "venues_select_all" on venues for select using (true);

-- prices: herkes okuyabilir, sadece giriş yapmış kullanıcı kendi adına insert edebilir
create policy "prices_select_all" on prices for select using (true);
create policy "prices_insert_own" on prices for insert with check (auth.uid() = reported_by);

-- favorites: kullanıcı sadece kendi satırlarını görebilir/ekleyebilir/silebilir
create policy "favorites_select_own" on favorites for select using (auth.uid() = user_id);
create policy "favorites_insert_own" on favorites for insert with check (auth.uid() = user_id);
create policy "favorites_delete_own" on favorites for delete using (auth.uid() = user_id);

-- Seed data: mevcut 4 mekan
insert into venues (name, district, city, img, rating, reviews, verified, distance) values
  ('Hayal Kahvesi', 'Nilüfer', 'Bursa', 'https://picsum.photos/seed/hayalkahvesi/400/300', 4.6, 1280, true, 1.2),
  ('Paddy''s Pub', 'Osmangazi', 'Bursa', 'https://picsum.photos/seed/paddys/400/300', 4.4, 860, true, 2.5),
  ('Roof Lounge', 'Nilüfer', 'Bursa', 'https://picsum.photos/seed/rooflounge/400/300', 4.7, 2130, true, 3.1),
  ('The Wall', 'Nilüfer', 'Bursa', 'https://picsum.photos/seed/thewall/400/300', 4.5, 640, false, 0.8);

-- Seed data: başlangıç fiyatları (reported_by null, sistem verisi)
insert into prices (venue_id, category, drink_name, price)
select id, 'Bira', 'Efes', 190 from venues where name = 'Hayal Kahvesi'
union all
select id, 'Bira', 'Bomonti', 170 from venues where name = 'Hayal Kahvesi'
union all
select id, 'Bira', 'Efes', 170 from venues where name = 'Paddy''s Pub'
union all
select id, 'Bira', 'Efes', 220 from venues where name = 'Roof Lounge'
union all
select id, 'Bira', 'Efes', 185 from venues where name = 'The Wall';
