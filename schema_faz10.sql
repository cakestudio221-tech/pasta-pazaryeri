-- NightCompare — Spam/Kötüye Kullanım Koruması (Rate Limiting)
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Fiyat bildirimi: kullanıcı başına 5 dakikada en fazla 10 giriş
create or replace function limit_price_submissions() returns trigger as $$
begin
  if (select count(*) from prices where reported_by = new.reported_by and created_at > now() - interval '5 minutes') >= 10 then
    raise exception 'Çok fazla fiyat girişi yaptın, birkaç dakika sonra tekrar dene';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_price_submissions_trigger before insert on prices
  for each row execute procedure limit_price_submissions();

-- Yorum: kullanıcı başına 10 dakikada en fazla 5 yorum
create or replace function limit_review_submissions() returns trigger as $$
begin
  if (select count(*) from reviews where user_id = new.user_id and created_at > now() - interval '10 minutes') >= 5 then
    raise exception 'Çok fazla yorum ekledin, birazdan tekrar dene';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_review_submissions_trigger before insert on reviews
  for each row execute procedure limit_review_submissions();

-- Yeni mekan: kullanıcı başına 1 saatte en fazla 3 mekan
create or replace function limit_venue_creation() returns trigger as $$
begin
  if new.created_by is not null and (select count(*) from venues where created_by = new.created_by and created_at > now() - interval '1 hour') >= 3 then
    raise exception 'Çok fazla mekan ekledin, bir süre sonra tekrar dene';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_venue_creation_trigger before insert on venues
  for each row execute procedure limit_venue_creation();

-- Doğrulama başvurusu: kullanıcı başına 1 günde en fazla 10 başvuru
create or replace function limit_verification_requests() returns trigger as $$
begin
  if (select count(*) from venue_verification_requests where user_id = new.user_id and created_at > now() - interval '1 day') >= 10 then
    raise exception 'Çok fazla başvuru yaptın, yarın tekrar dene';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_verification_requests_trigger before insert on venue_verification_requests
  for each row execute procedure limit_verification_requests();

-- Görüntülenme/ziyaret: aynı kullanıcı+mekan için kısa aralıklarla tekrar sayılmasın
-- (anonim kullanıcılar IP takibi olmadığı için bu korumanın dışında kalıyor — bilinen sınır)
create or replace function dedup_venue_view() returns trigger as $$
begin
  if new.user_id is not null and exists (
    select 1 from venue_views where venue_id = new.venue_id and user_id = new.user_id and created_at > now() - interval '60 seconds'
  ) then
    raise exception 'rate_limited';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger dedup_venue_view_trigger before insert on venue_views
  for each row execute procedure dedup_venue_view();

create or replace function dedup_venue_visit() returns trigger as $$
begin
  if new.user_id is not null and exists (
    select 1 from venue_visits where venue_id = new.venue_id and user_id = new.user_id and created_at > now() - interval '5 minutes'
  ) then
    raise exception 'rate_limited';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger dedup_venue_visit_trigger before insert on venue_visits
  for each row execute procedure dedup_venue_visit();
