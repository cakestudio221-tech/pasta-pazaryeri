-- NightCompare — Kullanıcı Adı (benzersiz) / Ad Soyad Ayrımı
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- "username" kolonu şimdiye kadar aslında ad-soyad'ı tutuyordu; artık ikisini ayırıyoruz:
-- full_name = ad soyad (sadece admin görür), handle = herkese açık, benzersiz kullanıcı adı
alter table profiles add column full_name text;
alter table profiles add column handle text;

update profiles set full_name = username where full_name is null;
update profiles set handle = 'kullanici_' || substr(id::text, 1, 8) where handle is null;

alter table profiles add constraint profiles_handle_unique unique (handle);

drop view if exists user_contribution_stats;
alter table profiles drop column username;

-- Liderlik tablosu artık kullanıcı adını (handle) gösterir
create or replace view user_contribution_stats as
select
  p.id as user_id,
  p.handle as username,
  coalesce(pr7.cnt,0) as contributions_7d,
  coalesce(pr30.cnt,0) as contributions_30d,
  coalesce(prall.cnt,0) as contributions_all
from profiles p
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '7 days' group by reported_by) pr7 on pr7.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '30 days' group by reported_by) pr30 on pr30.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null group by reported_by) prall on prall.reported_by = p.id;

-- Ad soyad, doğum tarihi ve e-posta gibi genel bilgileri sadece admin görebilsin
create or replace function admin_list_users()
returns table (id uuid, email text, full_name text, handle text, date_of_birth date, xp int, is_admin boolean, created_at timestamptz)
language sql security definer
as $$
  select p.id, u.email, p.full_name, p.handle, p.date_of_birth, p.xp, p.is_admin, p.created_at
  from profiles p join auth.users u on u.id = p.id
  where exists (select 1 from profiles me where me.id = auth.uid() and me.is_admin);
$$;
grant execute on function admin_list_users() to authenticated;
