-- NightCompare — Liderlik Tablosuna XP/Unvan Ekleme
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Mevcut sütunları bozmadan sona xp ekleniyor (create or replace view ortadaki sütunları değiştirmeye izin vermez)
create or replace view user_contribution_stats as
select
  p.id as user_id,
  p.handle as username,
  coalesce(pr7.cnt,0) as contributions_7d,
  coalesce(pr30.cnt,0) as contributions_30d,
  coalesce(prall.cnt,0) as contributions_all,
  p.xp
from profiles p
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '7 days' group by reported_by) pr7 on pr7.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '30 days' group by reported_by) pr30 on pr30.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null group by reported_by) prall on prall.reported_by = p.id;
