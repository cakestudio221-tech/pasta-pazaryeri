-- NightCompare — Mekan Onay Mekanizması
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.
--
-- Şu ana kadar kullanıcıların "+ Yeni mekan ekle" ile ekledikleri mekanlar
-- (verified:false olsa da) direkt herkese görünüyordu. Artık is_approved=false
-- olarak başlıyorlar ve admin (sen, Supabase Table Editor'den) onaylamadan
-- uygulamada görünmeyecekler.

alter table venues add column is_approved boolean not null default false;

-- Mevcut SQL seed mekanları (created_by NULL, yani uygulama üzerinden değil
-- senin tarafından eklenenler) otomatik onaylı sayılır. Şu ana kadar test
-- amaçlı uygulama içinden eklenmiş mekanlar (created_by dolu olanlar,
-- "rastgele isimli" test mekanın dahil) onaysız kalır.
update venues set is_approved = true where created_by is null;

-- Insert sırasında bir kullanıcının is_approved:true göndererek kendi
-- kendini onaylı yapmasını da RLS seviyesinde engelliyoruz.
drop policy "venues_insert_own" on venues;
create policy "venues_insert_own" on venues for insert with check (auth.uid() is not null and is_approved = false);
