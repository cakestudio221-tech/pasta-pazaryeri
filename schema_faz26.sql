-- NightCompare — İlk fiyat katkısını ödüllendir
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.
--
-- Amaç: 24 mekan var ama çoğunda fiyat yok. Bir mekanın ilk fiyatını girmek en
-- değerli katkı (mekanı boş listeden çıkarıp kullanılabilir hale getiriyor), o
-- yüzden 20 yerine 50 XP veriyor.

-- XP hesabı sunucuda kalmalı: istemci xp'yi yazamıyor (schema_faz23'teki
-- protect_xp_column koruması), bu yüzden bonus da burada hesaplanıyor.
create or replace function award_price_xp() returns trigger as $$
declare
  onceki_fiyat_sayisi int;
  kazanilan_xp int;
begin
  -- Bu satır dışında bu mekana ait fiyat var mı? Yoksa bu ilk katkı.
  select count(*) into onceki_fiyat_sayisi
    from prices
   where venue_id = new.venue_id and id <> new.id;

  kazanilan_xp := case when onceki_fiyat_sayisi = 0 then 50 else 20 end;

  update profiles set xp = xp + kazanilan_xp where id = new.reported_by;
  return new;
end;
$$ language plpgsql security definer;

-- Her mekanın ilk fiyatını kimin girdiği. Ayrı sütun tutmak yerine türetiliyor:
-- kaynak tek (prices), tutarsızlık ihtimali yok.
create or replace view venue_pioneers as
select distinct on (p.venue_id)
  p.venue_id,
  p.reported_by as user_id,
  pr.handle as username,
  p.created_at
from prices p
left join profiles pr on pr.id = p.reported_by
where p.reported_by is not null
order by p.venue_id, p.created_at asc;

-- View'ler istemciye açıkça yetkilendirilmeli; yoksa PostgREST onu hiç göstermez
-- ("schema cache" hatası aslında yetki eksikliğinden gelir).
grant select on venue_pioneers to anon, authenticated;
