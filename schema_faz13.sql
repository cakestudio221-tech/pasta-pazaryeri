-- NightCompare — Sohbete Emoji ve Fotoğraf Ekleme
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Fotoğraf mesajları için content'i opsiyonel yap, image_url ekle
alter table chat_messages add column image_url text;
alter table chat_messages alter column content drop not null;
alter table chat_messages drop constraint chat_messages_content_check;
alter table chat_messages add constraint chat_messages_content_check check (
  (content is not null and char_length(trim(content)) > 0 and char_length(content) <= 500) or image_url is not null
);

alter table venue_chat_messages add column image_url text;
alter table venue_chat_messages alter column content drop not null;
alter table venue_chat_messages drop constraint venue_chat_messages_content_check;
alter table venue_chat_messages add constraint venue_chat_messages_content_check check (
  (content is not null and char_length(trim(content)) > 0 and char_length(content) <= 500) or image_url is not null
);

-- Sohbet fotoğrafları için yeni bucket (venue-photos/avatars ile aynı desen — Faz 7)
insert into storage.buckets (id, name, public) values ('chat-attachments', 'chat-attachments', true) on conflict (id) do nothing;
create policy "chat_attachments_public_read" on storage.objects for select using (bucket_id = 'chat-attachments');
create policy "chat_attachments_auth_insert" on storage.objects for insert with check (bucket_id = 'chat-attachments' and auth.uid() is not null);
