-- NightCompare — FAZ 5: Çoklu Şehir Desteğinin Tamamlanması
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- category_price_stats artık şehir bazlı (venues ile join edilerek city_id eklendi)
-- Not: mevcut view'ın sütun sırasını bozmamak için city_id sona ekleniyor
-- (create or replace view, var olan sütunların adını/sırasını değiştirmeye izin vermiyor).
create or replace view category_price_stats as
select
  p.category,
  round(avg(p.price)::numeric, 2) as avg_price,
  min(p.price) as min_price,
  max(p.price) as max_price,
  count(*) as sample_count,
  v.city_id
from prices p
join venues v on v.id = p.venue_id
group by p.category, v.city_id;

grant select on category_price_stats to anon, authenticated;
