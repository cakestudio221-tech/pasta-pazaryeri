-- NightCompare — Mekan yıldız puanını gerçek yorumlardan otomatik hesapla
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.
-- ÖNEMLİ: Bu script mevcut mekanların rating/reviews alanlarını gerçek yorumlara göre yeniden yazar
-- (yorumu olmayanlar 0 olur — başlangıçta elle girilmiş sahte puanlar kaldırılır).

create or replace function update_venue_rating() returns trigger as $$
declare
  target_venue_id uuid;
begin
  target_venue_id := coalesce(new.venue_id, old.venue_id);
  update venues set
    rating = coalesce((select round(avg(rating)::numeric, 1) from reviews where venue_id = target_venue_id), 0),
    reviews = (select count(*) from reviews where venue_id = target_venue_id)
  where id = target_venue_id;
  return null;
end;
$$ language plpgsql security definer;

create trigger update_venue_rating_insert after insert on reviews for each row execute procedure update_venue_rating();
create trigger update_venue_rating_update after update on reviews for each row execute procedure update_venue_rating();
create trigger update_venue_rating_delete after delete on reviews for each row execute procedure update_venue_rating();

-- Mevcut tüm mekanları gerçek yorumlara göre yeniden hesapla (yorumu olmayanlar 0 olur)
update venues v set
  rating = coalesce((select round(avg(r.rating)::numeric,1) from reviews r where r.venue_id = v.id), 0),
  reviews = (select count(*) from reviews r where r.venue_id = v.id);
