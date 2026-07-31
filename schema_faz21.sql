-- NightCompare — Bildirimlere mekan bağlantısı ekle (tıklanınca ilgili mekana gidebilsin)
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

alter table notifications add column venue_id uuid references venues(id) on delete set null;

create or replace function notify_venue_approved() returns trigger as $$
begin
  if new.is_approved = true and old.is_approved = false and new.created_by is not null then
    insert into notifications (user_id, title, body, venue_id) values (new.created_by, 'Mekanın onaylandı! 🎉', new.name || ' artık herkese görünür.', new.id);
  end if;
  return new;
end;
$$ language plpgsql security definer;

create or replace function notify_verification_reviewed() returns trigger as $$
declare venue_name text;
begin
  if new.status in ('approved','rejected') and old.status = 'pending' then
    select name into venue_name from venues where id = new.venue_id;
    insert into notifications (user_id, title, body, venue_id) values (
      new.user_id,
      case when new.status='approved' then 'Doğrulama başvurun onaylandı ✅' else 'Doğrulama başvurun reddedildi' end,
      venue_name,
      new.venue_id
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;
