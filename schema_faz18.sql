-- NightCompare — Sohbet Admin Moderasyon Katmanı
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Kullanıcı durumu: susturma + sohbetten-ban (uygulama geneli ban zaten is_banned'de var)
alter table profiles add column muted_until timestamptz;
alter table profiles add column mute_reason text;
alter table profiles add column chat_banned boolean not null default false;
alter table profiles add column chat_ban_reason text;
alter table profiles add column ban_reason text;

-- Sohbet kilidi: genel sohbet şehir bazlı, mekan sohbeti mekan bazlı
alter table cities add column chat_locked boolean not null default false;
alter table venues add column chat_locked boolean not null default false;
create policy "cities_admin_update" on cities for update using (is_admin());

-- Mesajlarda admin rozeti — client'tan gelen değeri değil, trigger'ın hesapladığı gerçek değeri kullan
alter table chat_messages add column is_admin boolean not null default false;
alter table venue_chat_messages add column is_admin boolean not null default false;

-- Gönderim anında: mute/chat-ban/kilit kontrolü + gerçek is_admin damgası
create or replace function check_chat_send_allowed() returns trigger as $$
declare
  locked boolean;
begin
  if exists (select 1 from profiles where id = auth.uid() and muted_until is not null and muted_until > now()) then
    raise exception 'Susturuldunuz, mesaj gönderemezsiniz';
  end if;
  if exists (select 1 from profiles where id = auth.uid() and chat_banned) then
    raise exception 'Sohbetten banlandınız';
  end if;
  if TG_TABLE_NAME = 'chat_messages' then
    select coalesce(chat_locked,false) into locked from cities where id = new.city_id;
  else
    select coalesce(chat_locked,false) into locked from venues where id = new.venue_id;
  end if;
  if locked and not exists (select 1 from profiles where id = auth.uid() and is_admin) then
    raise exception 'Sohbet şu anda yönetici tarafından durduruldu';
  end if;
  new.is_admin := exists (select 1 from profiles where id = auth.uid() and is_admin);
  return new;
end;
$$ language plpgsql security definer;
create trigger check_chat_send_allowed_general before insert on chat_messages for each row execute procedure check_chat_send_allowed();
create trigger check_chat_send_allowed_venue before insert on venue_chat_messages for each row execute procedure check_chat_send_allowed();

-- Şikayetler (aynı mesaj+kişi ikinci kez şikayet edemesin — sayı, satır tekrarı değil grup sayımıyla gelir)
create table message_reports (
  id uuid primary key default gen_random_uuid(),
  chat_type text not null check (chat_type in ('general','venue')),
  message_id uuid not null,
  message_content text,
  message_image_url text,
  sender_user_id uuid,
  sender_username text,
  context_label text,
  reporter_user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (message_id, reporter_user_id)
);
alter table message_reports enable row level security;
create policy "message_reports_insert_own" on message_reports for insert with check (auth.uid() = reporter_user_id);
create policy "message_reports_select_admin" on message_reports for select using (is_admin());
create policy "message_reports_delete_admin" on message_reports for delete using (is_admin());
