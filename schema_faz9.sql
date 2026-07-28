-- NightCompare — Admin Paneli
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.
--
-- Çalıştırdıktan sonra kendini admin yapmak için Table Editor'de profiles
-- tablosunda kendi satırının is_admin alanını true yap. Bundan sonraki
-- her şey (mekan onayı, doğrulama başvuruları, şehir ekleme) uygulama
-- içindeki Admin Paneli'nden yapılabilir.

alter table profiles add column is_admin boolean not null default false;

create or replace function is_admin() returns boolean as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false);
$$ language sql stable security definer;

-- Kendi kendini admin yapmayı engelle: is_admin sadece mevcut bir admin tarafından değiştirilebilir
create or replace function protect_is_admin() returns trigger as $$
begin
  if new.is_admin is distinct from old.is_admin and not is_admin() then
    new.is_admin = old.is_admin;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger protect_is_admin_trigger before update on profiles
  for each row execute procedure protect_is_admin();

-- Mekan onayı: adminler is_approved güncelleyebilir ve reddedilen mekanı silebilir
create policy "venues_admin_update" on venues for update using (is_admin());
create policy "venues_admin_delete" on venues for delete using (is_admin());

-- Doğrulama başvuruları: adminler tüm bekleyenleri görüp statüyü değiştirebilir
create policy "vvr_admin_select_all" on venue_verification_requests for select using (is_admin());
create policy "vvr_admin_update" on venue_verification_requests for update using (is_admin());

-- Şehirler: adminler yeni şehir ekleyebilir
create policy "cities_admin_insert" on cities for insert with check (is_admin());
