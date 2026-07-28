-- NightCompare — Faz 9 Düzeltmesi: protect_is_admin trigger'ı Table Editor'ü de engelliyordu
-- schema_faz9.sql zaten çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.
--
-- Sorun: protect_is_admin_trigger, is_admin()'i kontrol ederken auth.uid() Table
-- Editor/Dashboard'dan yapılan düzenlemelerde boş geldiği için, admin'in kendi
-- elle yaptığı onaylamayı da "yetkisiz self-promote" sanıp geri alıyordu.
-- Düzeltme: sadece uygulama üzerinden (authenticated rolüyle) gelen istekleri
-- engelle, Dashboard/SQL Editor'den gelenlere dokunma.

create or replace function protect_is_admin() returns trigger as $$
begin
  if new.is_admin is distinct from old.is_admin
     and auth.role() = 'authenticated'
     and not is_admin() then
    new.is_admin = old.is_admin;
  end if;
  return new;
end;
$$ language plpgsql security definer;
