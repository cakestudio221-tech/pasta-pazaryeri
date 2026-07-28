-- NightCompare — FAZ 6: Canlı Sohbet
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Genel sohbet (şehir başına)
create table chat_messages (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  username text not null,
  avatar_url text,
  content text not null check (char_length(trim(content)) > 0 and char_length(content) <= 500),
  created_at timestamptz not null default now()
);
alter table chat_messages enable row level security;
create policy "chat_messages_select_all" on chat_messages for select using (true);
create policy "chat_messages_insert_own" on chat_messages for insert with check (auth.uid() = user_id);
create policy "chat_messages_admin_delete" on chat_messages for delete using (is_admin());

-- Mekan bazlı sohbet
create table venue_chat_messages (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  username text not null,
  avatar_url text,
  content text not null check (char_length(trim(content)) > 0 and char_length(content) <= 500),
  created_at timestamptz not null default now()
);
alter table venue_chat_messages enable row level security;
create policy "venue_chat_messages_select_all" on venue_chat_messages for select using (true);
create policy "venue_chat_messages_insert_own" on venue_chat_messages for insert with check (auth.uid() = user_id);
create policy "venue_chat_messages_admin_delete" on venue_chat_messages for delete using (is_admin());

-- Hız sınırlama (mevcut limit_price_submissions/limit_review_submissions deseniyle aynı)
create or replace function limit_chat_messages() returns trigger as $$
begin
  if (select count(*) from chat_messages where user_id = new.user_id and created_at > now() - interval '30 seconds') >= 15 then
    raise exception 'Çok hızlı mesaj gönderiyorsun, biraz yavaşla';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_chat_messages_trigger before insert on chat_messages
  for each row execute procedure limit_chat_messages();

create or replace function limit_venue_chat_messages() returns trigger as $$
begin
  if (select count(*) from venue_chat_messages where user_id = new.user_id and created_at > now() - interval '30 seconds') >= 15 then
    raise exception 'Çok hızlı mesaj gönderiyorsun, biraz yavaşla';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger limit_venue_chat_messages_trigger before insert on venue_chat_messages
  for each row execute procedure limit_venue_chat_messages();

-- Realtime yayınına ekle (Supabase varsayılan olarak tabloları otomatik yayınlamıyor)
alter publication supabase_realtime add table chat_messages;
alter publication supabase_realtime add table venue_chat_messages;
