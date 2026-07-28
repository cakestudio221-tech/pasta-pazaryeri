-- NightCompare — FAZ 2.2: Gece Rotası
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

alter table venues add column lat numeric;
alter table venues add column lng numeric;

update venues set lat = 40.2148, lng = 29.0533 where name = 'Hayal Kahvesi';
update venues set lat = 40.1885, lng = 29.0610 where name = 'Paddy''s Pub';
update venues set lat = 40.2201, lng = 29.0489 where name = 'Roof Lounge';
update venues set lat = 40.2165, lng = 29.0455 where name = 'The Wall';
