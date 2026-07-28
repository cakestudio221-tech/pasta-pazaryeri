-- NightCompare — reviews tablosu (Round 2 eklentisi)
-- schema.sql zaten çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

create table reviews (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

alter table reviews enable row level security;

create policy "reviews_select_all" on reviews for select using (true);
create policy "reviews_insert_own" on reviews for insert with check (auth.uid() = user_id);
