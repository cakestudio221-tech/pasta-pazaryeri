-- NightCompare — Profil Fotoğrafı+Biyografi, Kullanıcı Adı Değişikliği (günde 1),
-- Küfür Filtresi, Genel Kullanıcı Profili Görüntüleme, Admin Kullanıcı Yönetimi
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

alter table profiles add column bio text;
alter table profiles add column is_banned boolean not null default false;
alter table profiles add column handle_changed_at timestamptz;

-- Kullanıcı adında argo/küfür engeli (basit engelli-kelime listesi)
create or replace function validate_handle_content() returns trigger as $$
declare
  banned text[] := array['amk','aq','mk','sik','yarrak','oc','o.c','piç','pic','orospu','gotver','ibne','pezevenk','fuck','shit','bitch','asshole','cunt','nigger','fag'];
  w text;
  clean text;
begin
  if new.handle is distinct from old.handle then
    clean := lower(regexp_replace(new.handle, '[^a-z0-9]', '', 'g'));
    foreach w in array banned loop
      if position(w in clean) > 0 then
        raise exception 'Kullanıcı adında uygunsuz ifade kullanılamaz';
      end if;
    end loop;
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger validate_handle_content_trigger before update on profiles
  for each row execute procedure validate_handle_content();

-- Kullanıcı adını kendi başına günde sadece 1 kez değiştirebilsin (admin başkasının adını değiştirirse bu sınıra takılmaz)
create or replace function limit_handle_change() returns trigger as $$
begin
  if new.handle is distinct from old.handle then
    if auth.uid() = new.id and old.handle_changed_at is not null and old.handle_changed_at > now() - interval '24 hours' then
      raise exception 'Kullanıcı adını günde sadece bir kez değiştirebilirsin';
    end if;
    new.handle_changed_at = now();
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_handle_change_trigger before update on profiles
  for each row execute procedure limit_handle_change();

-- Admin, tüm kullanıcıları yönetebilsin (admin yap/kaldır, yasakla, kullanıcı adını sıfırla)
create policy "profiles_update_admin" on profiles for update using (
  exists (select 1 from profiles me where me.id = auth.uid() and me.is_admin)
);

-- Yasaklı kullanıcılar yeni mekan/fiyat/yorum/mesaj gönderemesin
create or replace function block_banned_user() returns trigger as $$
begin
  if exists (select 1 from profiles where id = auth.uid() and is_banned) then
    raise exception 'Hesabın askıya alındığı için bu işlemi yapamazsın';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger block_banned_prices before insert on prices for each row execute procedure block_banned_user();
create trigger block_banned_reviews before insert on reviews for each row execute procedure block_banned_user();
create trigger block_banned_chat before insert on chat_messages for each row execute procedure block_banned_user();
create trigger block_banned_venue_chat before insert on venue_chat_messages for each row execute procedure block_banned_user();
create trigger block_banned_venues before insert on venues for each row execute procedure block_banned_user();

-- Admin kullanıcı listesine yasak durumu da eklensin
drop function if exists admin_list_users();
create function admin_list_users()
returns table (id uuid, email text, full_name text, handle text, bio text, date_of_birth date, xp int, is_admin boolean, is_banned boolean, created_at timestamptz)
language sql security definer
as $$
  select p.id, u.email, p.full_name, p.handle, p.bio, p.date_of_birth, p.xp, p.is_admin, p.is_banned, p.created_at
  from profiles p join auth.users u on u.id = p.id
  where exists (select 1 from profiles me where me.id = auth.uid() and me.is_admin);
$$;
grant execute on function admin_list_users() to authenticated;
