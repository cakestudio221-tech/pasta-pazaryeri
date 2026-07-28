-- NightCompare — FAZ 1: Temel Keşif Özellikleri
-- schema.sql, schema_reviews.sql ve schema_faz0.sql zaten çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Trend skoru: son 7/30 gün görüntülenme + ziyaret sayısı
create or replace view venue_popularity as
select
  v.id as venue_id,
  v.city_id,
  coalesce(vv7.cnt,0) as views_7d,
  coalesce(vv30.cnt,0) as views_30d,
  coalesce(vs7.cnt,0) as visits_7d,
  coalesce(vs30.cnt,0) as visits_30d,
  coalesce(vv7.cnt,0) + coalesce(vs7.cnt,0)*3 as trend_score
from venues v
left join (select venue_id, count(*) cnt from venue_views where created_at > now() - interval '7 days' group by venue_id) vv7 on vv7.venue_id = v.id
left join (select venue_id, count(*) cnt from venue_views where created_at > now() - interval '30 days' group by venue_id) vv30 on vv30.venue_id = v.id
left join (select venue_id, count(*) cnt from venue_visits where created_at > now() - interval '7 days' group by venue_id) vs7 on vs7.venue_id = v.id
left join (select venue_id, count(*) cnt from venue_visits where created_at > now() - interval '30 days' group by venue_id) vs30 on vs30.venue_id = v.id;

grant select on venue_popularity to anon, authenticated;

-- Kategori bazlı fiyat istatistikleri
create or replace view category_price_stats as
select
  category,
  round(avg(price)::numeric, 2) as avg_price,
  min(price) as min_price,
  max(price) as max_price,
  count(*) as sample_count
from prices
group by category;

grant select on category_price_stats to anon, authenticated;
