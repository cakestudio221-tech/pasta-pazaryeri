-- NightCompare — Mekan Ekleme Akışı
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

alter table venues add column created_by uuid references profiles(id);

create policy "venues_insert_own" on venues for insert with check (auth.uid() is not null);
