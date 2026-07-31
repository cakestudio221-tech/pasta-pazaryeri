-- NightCompare — Fiyat doğrulaması + XP güvenlik açığı düzeltmesi
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Fiyat 0 veya negatif olamaz (DB seviyesinde — client-side kontrol tek başına yeterli değil)
alter table prices add constraint prices_price_positive check (price > 0);

-- XP artık sadece sunucu tarafında (fiyat bildirince otomatik) artsın; istemci doğrudan
-- profiles.xp'yi yazamasın (aksi halde konsoldan sınırsız XP/unvan verilebilir).
create or replace function award_price_xp() returns trigger as $$
begin
  update profiles set xp = xp + 20 where id = new.reported_by;
  return new;
end;
$$ language plpgsql security definer;
create trigger award_price_xp_trigger after insert on prices
  for each row execute procedure award_price_xp();

create or replace function protect_xp_column() returns trigger as $$
begin
  -- pg_trigger_depth() = 0 demek bu güncelleme doğrudan istemciden geldi demek (bizim
  -- award_price_xp gibi sunucu tetikleyicilerinin içinden değil) — sadece o durumda,
  -- admin değilse xp değişikliğini yok say.
  if pg_trigger_depth() = 0 and new.xp is distinct from old.xp and not is_admin() then
    new.xp := old.xp;
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger protect_xp_column_trigger before update on profiles
  for each row execute procedure protect_xp_column();
