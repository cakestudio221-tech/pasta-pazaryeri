-- NightCompare — Bursa gece hayatı mekanlarını OpenStreetMap'ten içe aktar
-- Veri kaynağı: © OpenStreetMap katkıcıları (ODbL). https://www.openstreetmap.org/copyright
-- 19 mekan, gerçek koordinatlarıyla. "Hayal Kahvesi" zaten kayıtlı olduğu için atlandı.
-- Aynı ada sahip mekan varsa tekrar eklenmez (idempotent — birden fazla kez çalıştırılabilir).
--
-- Not: city_id (uuid) ve amenities (text[]) sütunları için açık tip dönüşümü şart;
-- VALUES içindeki metin sabitleri varsayılan olarak text kabul edilir ve
-- PostgreSQL bunları uuid/diziye kendiliğinden çevirmez.

insert into venues (name, district, city, city_id, lat, lng, distance, img, rating, reviews, verified, is_approved, working_hours, amenities)
select yeni.name, yeni.district, yeni.city, yeni.city_id::uuid, yeni.lat, yeni.lng, yeni.distance, yeni.img,
       yeni.rating, yeni.reviews, yeni.verified, yeni.is_approved, yeni.working_hours, yeni.amenities::text[]
from (values
  ('Tabipler Lokali', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.181198, 29.069009, 1.1, 'https://picsum.photos/seed/tabiplerlokali/400/300', 0, 0, false, true, null::text, '{}'),
  ('Nona Hookah Lounge', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.226598, 28.980115, 8.1, 'https://picsum.photos/seed/nonahookahlounge/400/300', 0, 0, false, true, null, '{}'),
  ('Demo', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.22129, 28.977878, 7.9, 'https://picsum.photos/seed/demo/400/300', 0, 0, false, true, null, '{}'),
  ('La Luz', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.249681, 28.960127, 10.9, 'https://picsum.photos/seed/laluz/400/300', 0, 0, false, true, null, '{}'),
  ('Last Point - Ocakbaşı', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.21131, 28.997903, 5.9, 'https://picsum.photos/seed/lastpointocakba/400/300', 0, 0, false, true, null, '{}'),
  ('Kat3 Teras', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.22004, 28.958581, 9.4, 'https://picsum.photos/seed/kat3teras/400/300', 0, 0, false, true, null, '{}'),
  ('Caddeüstü', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.225454, 28.914544, 13.1, 'https://picsum.photos/seed/caddest/400/300', 0, 0, false, true, null, '{}'),
  ('High Out', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.209466, 29.02162, 4.1, 'https://picsum.photos/seed/highout/400/300', 0, 0, false, true, '10:00-22:00', '{}'),
  ('Şey Pub', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.210584, 28.999503, 5.8, 'https://picsum.photos/seed/eypub/400/300', 0, 0, false, true, null, '{}'),
  ('6:45 Kaybedenler Kulübü', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.227891, 28.979975, 8.2, 'https://picsum.photos/seed/645kaybedenlerkulb/400/300', 0, 0, false, true, null, '{}'),
  ('Hakanın mekanı', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.220813, 28.993547, 6.8, 'https://picsum.photos/seed/hakannmekan/400/300', 0, 0, false, true, 'Mo-Su 09:00-21:00', '{}'),
  ('The North Shield', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.226302, 28.970479, 8.8, 'https://picsum.photos/seed/thenorthshield/400/300', 0, 0, false, true, null, '{}'),
  ('David People', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.226232, 28.970444, 8.8, 'https://picsum.photos/seed/davidpeople/400/300', 0, 0, false, true, null, '{}'),
  ('Tosca Italiano', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.225509, 28.969998, 8.8, 'https://picsum.photos/seed/toscaitaliano/400/300', 0, 0, false, true, null, '{}'),
  ('Cihangir', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.225553, 28.969874, 8.8, 'https://picsum.photos/seed/cihangir/400/300', 0, 0, false, true, null, '{}'),
  ('Barınaq', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.209702, 29.021575, 4.1, 'https://picsum.photos/seed/barnaq/400/300', 0, 0, false, true, '10:00-22:00', '{}'),
  ('Just Beer', 'Nilüfer', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.225569, 28.914609, 13.1, 'https://picsum.photos/seed/justbeer/400/300', 0, 0, false, true, null, '{}'),
  ('Ivory Pub', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.202932, 29.030811, 3.0, 'https://picsum.photos/seed/ivorypub/400/300', 0, 0, false, true, null, '{}'),
  ('Başkent Restaurant', 'Osmangazi', 'Bursa', '85eb320e-ee58-4c57-a9e6-3688c1c81e0e', 40.192212, 29.076766, 1.4, 'https://picsum.photos/seed/bakentrestaurant/400/300', 0, 0, false, true, null, '{}')
) as yeni(name, district, city, city_id, lat, lng, distance, img, rating, reviews, verified, is_approved, working_hours, amenities)
where not exists (
  select 1 from venues v
  where lower(trim(v.name)) = lower(trim(yeni.name)) and v.city_id = yeni.city_id::uuid
);

-- Mevcut "Hayal Kahvesi" kaydının koordinatı gerçekle uyuşmuyordu; OSM değeriyle düzelt.
update venues set lat = 40.221633, lng = 28.977895
where lower(trim(name)) = 'hayal kahvesi' and city_id = '85eb320e-ee58-4c57-a9e6-3688c1c81e0e';
